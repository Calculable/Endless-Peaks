//
//  DisplayRedrawDriver.swift
//  MountainGenerator
//
//  Created by Jan Huber on 01.01.2026.
//


#if os(iOS) || os(tvOS) || os(visionOS)
    import QuartzCore
#elseif os(macOS)
    import CoreVideo
#endif

/// Calls `onFrame` once per display refresh.
/// - On iOS: CADisplayLink (main thread)
/// - On macOS: CVDisplayLink (realtime background thread; we hop to main)
final class DisplayRedrawDriver {
    typealias FrameCallback =
        @MainActor (_ timestampSeconds: TimeInterval) -> Void

    private let onFrame: FrameCallback

    #if os(iOS) || os(tvOS) || os(visionOS)
        private var displayLink: CADisplayLink?
    #elseif os(macOS)
        private var displayLink: CVDisplayLink?
    #endif

    init(onFrame: @escaping FrameCallback) {
        self.onFrame = onFrame
    }

    func start() {
        #if os(iOS) || os(tvOS) || os(visionOS)
            stop()
            let link = CADisplayLink(
                target: self,
                selector: #selector(tick(_:))
            )
            // Let the system run at the native refresh rate (60/120/etc).
            // If you *want* to request up to 120 on capable devices, uncomment:
            // link.preferredFrameRateRange = .init(minimum: 30, maximum: 120, preferred: 120)
            link.add(to: .main, forMode: .common)
            displayLink = link

        #elseif os(macOS)
            stop()
            var link: CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays(&link)
            displayLink = link
            guard let displayLink else { return }

            CVDisplayLinkSetOutputCallback(
                displayLink,
                { _, _, outTime, _, _, userInfo -> CVReturn in
                    let me = Unmanaged<DisplayRedrawDriver>.fromOpaque(
                        userInfo!
                    ).takeUnretainedValue()

                    let ts = outTime.pointee
                    let seconds =
                        (Double(ts.videoTime) / Double(ts.videoTimeScale))

                    // CVDisplayLink is NOT on the main thread -> hop to main.
                    Task { @MainActor in
                        await Task.yield()
                        me.onFrame(seconds)
                    }
                    return kCVReturnSuccess
                },
                Unmanaged.passUnretained(self).toOpaque()
            )

            CVDisplayLinkStart(displayLink)
        #endif
    }

    func stop() {
        #if os(iOS) || os(tvOS) || os(visionOS)
            displayLink?.invalidate()
            displayLink = nil
        #elseif os(macOS)
            if let displayLink {
                CVDisplayLinkStop(displayLink)
            }
            displayLink = nil
        #endif
    }

    deinit { stop() }

    #if os(iOS) || os(tvOS) || os(visionOS)
        @objc private func tick(_ link: CADisplayLink) {
            Task { @MainActor in
                await Task.yield()
                onFrame(link.timestamp)
            }
        }
    #endif
}
