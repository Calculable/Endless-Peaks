import SwiftUI
import AVFoundation
import CoreVideo
import CoreGraphics
import CoreImage
#if canImport(UIKit)
import UIKit
private typealias PlatformView = UIView
#elseif canImport(AppKit)
import AppKit
private typealias PlatformView = NSView
#endif

// Shared CIContext for the dithering helper
private let sharedCIContext = CIContext(options: nil)

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
        scale: CGFloat = 2.0,
        ditherStrength: CGFloat = 0.04,
        preferHEVCMain10: Bool = true,
        useProRes422: Bool = false
    ) async throws {

        try? FileManager.default.removeItem(at: outputURL)

        // 1) Build SwiftUI view ONCE
        let rootView = AnimationView(configuration: configuration, engine: engine)
            .frame(width: size.width, height: size.height)

        // 2) Host it ONCE
        #if canImport(UIKit)
        let host = UIHostingController(rootView: rootView)
        host.view.bounds = CGRect(origin: .zero, size: size)
        host.view.backgroundColor = .clear

        let container = PlatformView(frame: host.view.bounds)
        container.backgroundColor = .clear
        container.addSubview(host.view)
        host.view.frame = container.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.setNeedsLayout()
        container.layoutIfNeeded()
        #elseif canImport(AppKit)
        let host = NSHostingView(rootView: rootView)
        host.frame = CGRect(origin: .zero, size: size)

        let container = PlatformView(frame: host.bounds)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        container.addSubview(host)
        host.frame = container.bounds
        container.layoutSubtreeIfNeeded()
        #endif

        // 3) Writer setup
        let proResAvailable: Bool = {
            #if os(macOS)
            return true
            #else
            return false
            #endif
        }()
        let prefersProRes = useProRes422 && proResAvailable
        let prefersHEVC = preferHEVCMain10 && !prefersProRes

        let fileType: AVFileType = prefersProRes ? .mov : .mp4
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: fileType)

        // Use raw-value to avoid missing symbol on platforms without ProRes constants
        let proResCodec = AVVideoCodecType(rawValue: "apcn")
        let videoCodec: AVVideoCodecType = prefersProRes
            ? proResCodec
            : (prefersHEVC ? .hevc : .h264)

        let targetBitrate = prefersProRes
            ? max(80_000_000, Int(size.width * size.height * 30))
            : max(18_000_000, Int(size.width * size.height * 14))

        var compressionProps: [String: Any] = [
            AVVideoAverageBitRateKey: targetBitrate,
            AVVideoMaxKeyFrameIntervalKey: fps * 2
        ]
        if prefersHEVC {
            compressionProps[AVVideoProfileLevelKey] = "HEVC_Main10_AutoLevel"
        } else if !prefersProRes {
            compressionProps[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: videoCodec,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: compressionProps,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ]
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
            #if canImport(UIKit)
            container.setNeedsLayout()
            container.layoutIfNeeded()
            #elseif canImport(AppKit)
            container.layoutSubtreeIfNeeded()
            #endif

            // Snapshot hosted view -> CGImage
            guard let cgImage = snapshotCGImage(of: container, size: size, scale: scale) else {
                continue
            }

            // Subtle noise to break up gradient bands
            let dithered = applyDither(to: cgImage, amount: ditherStrength) ?? cgImage

            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 1_000_000)
            }

            guard let pixelBuffer = makePixelBuffer(width: Int(size.width), height: Int(size.height)) else {
                continue
            }
            draw(dithered, into: pixelBuffer)

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
private func snapshotCGImage(of view: PlatformView, size: CGSize, scale: CGFloat) -> CGImage? {
    #if canImport(UIKit)
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { _ in
        view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
    return image.cgImage
    #elseif canImport(AppKit)
    let bounds = CGRect(origin: .zero, size: size)
    guard let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
    view.cacheDisplay(in: bounds, to: rep)
    return rep.cgImage
    #endif
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

private func applyDither(to cgImage: CGImage, amount: CGFloat) -> CGImage? {
    guard amount > 0 else { return cgImage }

    let input = CIImage(cgImage: cgImage)
    guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
        .cropped(to: input.extent)
    else { return cgImage }

    // Scale the noise amplitude way down to keep it invisible but effective
    let scaledNoise = noise.applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: amount, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: amount, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: amount, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0)
    ])

    let dithered = scaledNoise.applyingFilter("CIAdditionCompositing", parameters: [
        kCIInputBackgroundImageKey: input
    ])

    return sharedCIContext.createCGImage(dithered, from: input.extent)
}
