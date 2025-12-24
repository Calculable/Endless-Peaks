//
//  ContentView.swift
//  MontainGenerator
//
//  Created by Jan Huber on 15.12.2025.
//

import Foundation
import SwiftUI

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
                onFrame(link.timestamp)
            }
        }
    #endif
}

struct ContentView: View {
    let numberOfMountains = 10
    @State private var maxPointsPerDepth = 5
    @State private var depth = 5
    @State private var driver: DisplayRedrawDriver?
    @State private var animationValue: CGFloat = 0.0

    var background: some View {
        Rectangle()
            .fill(
                Gradient(stops: [
                    .init(color: Color.blue, location: 0)
                    // .init(color: Color.white, location: 0.5)
                ])
            )
    }

    @State private var mountains = [MountainConfiguration]()

    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geo in
                    background

                    ForEach(Array(mountains.enumerated()), id: \.1.id) {
                        (index, mountain) in

                        ZStack {
                            Color.blue
                            Color.black.opacity(
                                CGFloat(index) / CGFloat(numberOfMountains)
                            )  // your 50% overlay base
                        }
                        .clipShape(Mountain(configuration: mountain))
                        .scaleEffect(CGFloat(1) + ((animationValue / CGFloat(10.0)) * CGFloat(index)), anchor: .top)
                        .offset(
                            x: 0,
                            y: (geo.size.height / Double(numberOfMountains))
                                * Double(index)
                                + (animationValue * CGFloat(index*100))
                        )

                    }

                }

            }

            VStack {

                Slider(
                    value: Binding(
                        get: { Double(maxPointsPerDepth) },
                        set: { maxPointsPerDepth = Int($0.rounded()) }
                    ),
                    in: 1...10,
                    step: 1
                )

                Slider(
                    value: Binding(
                        get: { Double(depth) },
                        set: { depth = Int($0.rounded()) }
                    ),
                    in: 1...7,
                    step: 1
                )
            }.padding()
        }
        .onAppear {
            regenerateMountains()
            driver = DisplayRedrawDriver { t in
                // Called once per refresh (main actor)
                // e.g. update @State, run simulation step, etc.
                // print(t)
                animationValue += 0.001
            }
            driver?.start()
        }
        .onDisappear {
            driver?.stop()
        }
        .onChange(of: maxPointsPerDepth) {
            regenerateMountains()
        }
        .onChange(of: depth) {
            regenerateMountains()
        }
    }

    func regenerateMountains() {

        mountains.removeAll()

        for _ in 0..<numberOfMountains {
            let mountain = MountainConfiguration(
                maxPointsPerDepth: maxPointsPerDepth,
                depth: depth
            )
            mountains.append(mountain)
        }

    }
}

#if canImport(UIKit)
    import UIKit
    typealias PlatformColor = UIColor
#elseif canImport(AppKit) 
    import AppKit
    typealias PlatformColor = NSColor
#endif

extension Color {

    /// Returns a lighter version of this color, where `step == total` becomes white (or very close).
    /// Works on both UIKit and AppKit.
    func lighter(step: Int, total: Int) -> Color {
        let t = CGFloat(max(0, min(step, total))) / CGFloat(max(total, 1))

        #if canImport(UIKit)
            let pc = PlatformColor(self)

            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            guard pc.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            else { return self }

            let newS = max(0, s * (1 - t))  // fade saturation to 0 (white)
            let newB = b + (1 - b) * t  // lift brightness to 1

            return Color(
                PlatformColor(
                    hue: h,
                    saturation: newS,
                    brightness: newB,
                    alpha: a
                )
            )

        #elseif canImport(AppKit)
            // NSColor needs to be in an RGB-compatible space before extracting HSB.
            guard let rgb = PlatformColor(self).usingColorSpace(.deviceRGB)
            else { return self }

            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

            let newS = max(0, s * (1 - t))
            let newB = b + (1 - b) * t

            return Color(
                PlatformColor(
                    calibratedHue: h,
                    saturation: newS,
                    brightness: newB,
                    alpha: a
                )
            )
        #endif
    }
}
extension Color {

    public static func random(randomOpacity: Bool = false) -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            opacity: randomOpacity ? .random(in: 0...1) : 1
        )
    }
}

// MARK: - Seeded RNG (repeatable randomness)
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed != 0 ? seed : 0xDEAD_BEEF
    }

    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - Configuration (precomputes once)
struct MountainConfiguration: Identifiable {
    let maxPointsPerDepth: Int
    let depth: Int
    let seed: UInt64
    let id = UUID()

    /// Stored ridge points in unit space (x,y in 0...1), left -> right.
    let ridgeUnitPoints: [CGPoint]

    init(maxPointsPerDepth: Int, depth: Int, seed: UInt64? = nil) {
        self.maxPointsPerDepth = maxPointsPerDepth
        self.depth = depth
        let seed = seed ?? UInt64.random(in: UInt64.min...UInt64.max)
        self.seed = seed
        var rng = SeededGenerator(seed: seed)

        // Unit-space endpoints (x fixed, y random)
        let start = CGPoint(
            x: 0.0,
            y: CGFloat.random(in: 0.0...1.0, using: &rng)
        )
        let end = CGPoint(x: 1.0, y: CGFloat.random(in: 0.0...1.0, using: &rng))

        self.ridgeUnitPoints = MountainConfiguration.buildSegmentPoints(
            from: start,
            to: end,
            maxPointsPerDepth: maxPointsPerDepth,
            currentDepth: depth,
            rng: &rng
        )
    }

    /// Same points every time; just scaled into rect.
    func ridgePoints(in rect: CGRect) -> [CGPoint] {
        ridgeUnitPoints.map { p in
            CGPoint(
                x: rect.minX + p.x * rect.width,
                y: rect.minY + p.y * rect.height
            )
        }
    }

    private static func buildSegmentPoints(
        from a: CGPoint,
        to b: CGPoint,
        maxPointsPerDepth: Int,
        currentDepth: Int,
        rng: inout SeededGenerator
    ) -> [CGPoint] {
        guard currentDepth > 0 else {
            return [a, b]
        }

        let minY = min(a.y, b.y)
        let maxY = max(a.y, b.y)

        let count = maxPointsPerDepth
        let width = b.x - a.x
        let step = width / (CGFloat(count) + 1.0)

        var mids: [CGPoint] = []
        mids.reserveCapacity(count)

        for i in 1...count {
            let x = a.x + step * CGFloat(i)
            let y = CGFloat.random(in: minY...maxY, using: &rng)
            mids.append(CGPoint(x: x, y: y))
        }

        let chain = [a] + mids + [b]

        var result: [CGPoint] = []
        for i in 0..<(chain.count - 1) {
            let left = chain[i]
            let right = chain[i + 1]

            let seg = buildSegmentPoints(
                from: left,
                to: right,
                maxPointsPerDepth: maxPointsPerDepth,
                currentDepth: currentDepth - 1,
                rng: &rng
            )

            // stitch without duplicating points
            if i == 0 {
                result.append(contentsOf: seg)
            } else {
                result.append(contentsOf: seg.dropFirst())
            }
        }

        return result
    }
}

// MARK: - Dumb Shape
struct Mountain: Shape {
    let configuration: MountainConfiguration

    func path(in rect: CGRect) -> Path {
        let ridge = configuration.ridgePoints(in: rect)
        guard let first = ridge.first else { return Path() }

        var path = Path()
        path.move(to: first)
        for p in ridge.dropFirst() { path.addLine(to: p) }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ContentView()
}
