import SwiftUI
import UIKit
import AVFoundation
import CoreVideo
import CoreGraphics

// MARK: - Exporter

@MainActor
public final class AnimationVideoExporter {

    public init() {}

     func export(
        configuration: MountainsConfiguration,
        engine: AnimationEngine,
        outputURL: URL,
        size: CGSize,
        fps: Int = 60,
        frameCount: Int,
        scale: CGFloat = 2.0
    ) async throws {

        try? FileManager.default.removeItem(at: outputURL)

        // 1) Build SwiftUI view ONCE
        let rootView = AnimationView(configuration: configuration, engine: engine)
            .frame(width: size.width, height: size.height)

        // 2) Host it ONCE
        let host = UIHostingController(rootView: rootView)
        host.view.bounds = CGRect(origin: .zero, size: size)
        host.view.backgroundColor = .clear

        // Put host.view into a temporary container so it behaves like a real view hierarchy.
        // (This helps SwiftUI actually run updates reliably.)
        let container = UIView(frame: host.view.bounds)
        container.backgroundColor = .clear
        container.addSubview(host.view)
        host.view.frame = container.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Force initial layout
        container.setNeedsLayout()
        container.layoutIfNeeded()

        // 3) Writer setup
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height),
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ]
        )

        guard writer.canAdd(input) else {
            throw NSError(domain: "AnimationVideoExporter", code: -10, userInfo: [
                NSLocalizedDescriptionKey: "AVAssetWriter cannot add input."
            ])
        }
        writer.add(input)

        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "AnimationVideoExporter", code: -11, userInfo: [
                NSLocalizedDescriptionKey: "AVAssetWriter failed to startWriting."
            ])
        }
        writer.startSession(atSourceTime: .zero)

        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))

        // 4) Frame loop
        for frameIndex in 0..<frameCount {
            print("frame: \(frameIndex)")
            engine.nextFrame()

            // Let Combine/SwiftUI process @Published and run body/onChange.
            // This is the key difference vs the ImageRenderer-only approach.
            await tickMainRunLoopOnce()

            // Ensure layout is current
            container.setNeedsLayout()
            container.layoutIfNeeded()

            // Snapshot hosted view -> CGImage
            guard let cgImage = snapshotCGImage(of: container, size: size, scale: scale) else {
                continue
            }

            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 1_000_000)
            }

            guard let pixelBuffer = makePixelBuffer(width: Int(size.width), height: Int(size.height)) else {
                continue
            }
            draw(cgImage, into: pixelBuffer)

            let pts = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
            if !adaptor.append(pixelBuffer, withPresentationTime: pts) {
                throw writer.error ?? NSError(domain: "AnimationVideoExporter", code: -12, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to append frame \(frameIndex)."
                ])
            }
        }

        input.markAsFinished()

        await withCheckedContinuation { cont in
            writer.finishWriting { cont.resume() }
        }

        if let err = writer.error {
            throw err
        }
    }
}

// MARK: - "Tick" helper (lets SwiftUI react)

@MainActor
private func tickMainRunLoopOnce() async {
    // Using a continuation on the main queue guarantees we yield
    // until the next iteration of the run loop.
    await withCheckedContinuation { cont in
        DispatchQueue.main.async {
            cont.resume()
        }
    }
}

// MARK: - Snapshot UIView -> CGImage

@MainActor
private func snapshotCGImage(of view: UIView, size: CGSize, scale: CGFloat) -> CGImage? {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { _ in
        // afterScreenUpdates:true helps ensure we capture the updated frame
        view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
    return image.cgImage
}

// MARK: - PixelBuffer + draw

private func makePixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    let attrs: [CFString: Any] = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true
    ]
    var pb: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        attrs as CFDictionary,
        &pb
    )
    return status == kCVReturnSuccess ? pb : nil
}

private func draw(_ cgImage: CGImage, into pixelBuffer: CVPixelBuffer) {
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

    guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(
        CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    )

    guard let ctx = CGContext(
        data: base,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else { return }

    ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))
    ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
}
