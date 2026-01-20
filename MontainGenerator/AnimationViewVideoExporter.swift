import SwiftUI
import AVFoundation
import CoreVideo
import CoreGraphics
#if canImport(UIKit)
import UIKit
private typealias PlatformView = UIView
#elseif canImport(AppKit)
import AppKit
private typealias PlatformView = NSView
#endif

// MARK: - Exporter

@MainActor
public final class AnimationVideoExporter {

    public init() {}

    func export(
        configuration: MountainsConfiguration,
        engine: AnimationEngine,
        outputName: String,
        size: CGSize,
        fps: Int = 60,
        frameCount: Int,
        progress: (@MainActor (_ renderedFrames: Int, _ totalFrames: Int) -> Void)? = nil
    ) async throws {

        let documentsURL =
            FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory

        let outputURL = documentsURL.appendingPathComponent(
            "\(outputName).mp4"
        )

        if FileManager.default.fileExists(
            atPath: outputURL.path
        ) {
            try? FileManager.default.removeItem(at: outputURL)
        }


        do {
            progress?(0, frameCount)
            let startedAt = Date()
            print("Export started: \(frameCount) frames @ \(fps) fps, \(Int(size.width))x\(Int(size.height)) -> \(outputURL.lastPathComponent)")

            // Build the SwiftUI view once at the exact video size
            let rootView = AnimationView(
                configuration: configuration,
                engine: engine,
                initialAspectRatio: size.width / max(size.height, 1)
            )
                .frame(width: size.width, height: size.height)

            // Host it for snapshotting
            #if canImport(UIKit)
            let host = UIHostingController(rootView: rootView)
            host.view.bounds = CGRect(origin: .zero, size: size)
            host.view.backgroundColor = .clear

            let container = PlatformView(frame: host.view.bounds)
            container.backgroundColor = .clear
            container.addSubview(host.view)
            host.view.frame = container.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            #elseif canImport(AppKit)
            let host = NSHostingView(rootView: rootView)
            host.frame = CGRect(origin: .zero, size: size)

            let container = PlatformView(frame: host.bounds)
            container.wantsLayer = true
            container.layer?.backgroundColor = NSColor.clear.cgColor
            container.addSubview(host)
            host.frame = container.bounds
            #endif

            // Basic H.264 writer
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
                    kCVPixelBufferHeightKey as String: Int(size.height)
                ]
            )

            guard writer.canAdd(input) else {
                throw NSError(domain: "AnimationVideoExporter", code: -10, userInfo: [NSLocalizedDescriptionKey: "Cannot add input"]) }
            writer.add(input)

            guard writer.startWriting() else {
                throw writer.error ?? NSError(domain: "AnimationVideoExporter", code: -11, userInfo: [NSLocalizedDescriptionKey: "Failed to start writing"]) }
            writer.startSession(atSourceTime: .zero)

            let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))

            for frameIndex in 0..<frameCount {
                try Task.checkCancellation()

                engine.nextFrame()
                await tickMainRunLoopOnce()

                guard let cgImage = snapshotCGImage(of: container, size: size) else { continue }
                guard let pixelBuffer = makePixelBuffer(width: Int(size.width), height: Int(size.height)) else { continue }
                draw(cgImage, into: pixelBuffer)

                while !input.isReadyForMoreMediaData {
                    try Task.checkCancellation()
                    try await Task.sleep(nanoseconds: 1_000_000)
                }

                let pts = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
                if !adaptor.append(pixelBuffer, withPresentationTime: pts) {
                    throw writer.error ?? NSError(domain: "AnimationVideoExporter", code: -12, userInfo: [NSLocalizedDescriptionKey: "Failed to append frame"]) }

                let rendered = frameIndex + 1
                progress?(rendered, frameCount)

                if rendered == 1 || rendered == frameCount || rendered % max(1, frameCount / 100) == 0 {
                    let remaining = frameCount - rendered
                    print("\(outputName) Rendered \(rendered)/\(frameCount) frames (\(remaining) remaining)")
                }
            }

            input.markAsFinished()
            await withCheckedContinuation { cont in writer.finishWriting { cont.resume() } }
            if let err = writer.error { throw err }

            let elapsed = Date().timeIntervalSince(startedAt)
            print("Export finished: \(outputURL.absoluteString) in \(String(format: "%.2fs", elapsed))")
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            print("Export failed: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Helpers

@MainActor
private func tickMainRunLoopOnce() async {
    await withCheckedContinuation { cont in DispatchQueue.main.async { cont.resume() } }
}

@MainActor
private func snapshotCGImage(of view: PlatformView, size: CGSize) -> CGImage? {
    #if canImport(UIKit)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
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

private func makePixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    var pb: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        nil,
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
