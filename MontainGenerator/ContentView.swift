//
//  ContentView.swift
//  MontainGenerator
//
//  Created by Jan Huber on 15.12.2025.
//

import Foundation
import SwiftUI

private struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension View {
    func readSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: SizeKey.self, value: geo.size)
            }
        )
        .onPreferenceChange(SizeKey.self, perform: onChange)
    }
}

struct ContentView: View {
    let numberOfMountains = 10
    @State private var maxPointsPerDepth = 3
    @State private var depth = 2
    @State private var driver: DisplayRedrawDriver?
    @State private var animationValue: CGFloat = 0.0
    @State private var speed: CGFloat = 0.01
    @State private var zoomEffect: CGFloat = 1.5
    @State private var offsetEffect: CGFloat = 3
    @State private var aspectRatio: CGFloat = 1

    let backgroundColor = Color.random()
    let foregroundColor = Color.random()

    let maxAnimationValue = CGFloat(1)

    var background: some View {
        
        Rectangle()
            .fill(
                Gradient(stops: [
                    .init(color: backgroundColor, location: 0),
                    .init(color: Color.white, location: 0.5),
                ])
            )
    }

    var mountainsView: some View {
        GeometryReader { geo in
            ForEach(Array(mountains.enumerated()), id: \.1.id) {
                (index, mountain) in

                let nearness = nearness(index: index)

                ZStack {
                    background
                    /*Color.black.opacity(
                        CGFloat(index) / CGFloat(numberOfMountains)
                    )*/ // your 50% overlay base
                    foregroundColor.opacity(nearness*nearness)
                }
                .clipShape(Mountain(configuration: mountain))
                .scaleEffect(
                    CGFloat(1) + (nearness) * zoomEffect,
                    anchor: .top
                )
                .offset(
                    x: 0,
                    y: geo.size.height * pow(nearness, offsetEffect)
                )

            }
        }
    }

    @State private var mountains = [MountainConfiguration]()

    var body: some View {
        VStack {
            GeometryReader { geo in

            ZStack {
                    background

                    mountainsView


                }.onChange(of: geo.size) { _, newSize in
                    aspectRatio = newSize.width / max(newSize.height, 1)
                }

            }


            VStack {

                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(maxPointsPerDepth) },
                            set: { maxPointsPerDepth = Int($0.rounded()) }
                        ),
                        in: 1...10,
                        step: 1
                    )

                    Text("maxPointsPerDepth: \(maxPointsPerDepth)")

                }

                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(depth) },
                            set: { depth = Int($0.rounded()) }
                        ),
                        in: 1...7,
                        step: 1
                    )

                    Text("depth: \(depth)")


                }

                HStack {

                    Slider(
                        value: Binding(
                            get: { speed },
                            set: { speed = $0 }
                        ),
                        in: 0.01...1.0,
                        step: 0.01
                    )

                    Text("speed: \(speed)")


                }

                HStack {

                    Slider(
                        value: Binding(
                            get: { zoomEffect },
                            set: { zoomEffect = $0 }
                        ),
                        in: 0.01...10,
                        step: 0.01
                    )

                    Text("zoomEffect: \(zoomEffect)")


                }

                HStack {

                    Slider(
                        value: Binding(
                            get: { offsetEffect },
                            set: { offsetEffect = $0 }
                        ),
                        in: 0.01...10,
                        step: 0.01
                    )

                    Text("offsetEffect: \(offsetEffect)")


                }
            }.padding()
        }
        .onAppear {
            regenerateMountains()
            driver = DisplayRedrawDriver { t in
                // Called once per refresh (main actor)
                // e.g. update @State, run simulation step, etc.
                // print(t)
                print(aspectRatio)
                animationValue += speed
                if animationValue >= maxAnimationValue {
                    animationValue = 0
                    let mountain = MountainConfiguration(
                        maxPointsPerDepth: max(1, maxPointsPerDepth*Int(aspectRatio)),
                        depth: depth
                    )
                    mountains.insert(mountain, at: 0)  //könnte effizienter sein, wenn ich hinten anhänge
                    mountains.removeLast()
                }
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

    func nearness(index: Int) -> CGFloat {
        //von 0 bis 1

        let index = CGFloat(index)
        let animationValue = CGFloat(animationValue)
        let numberOfMountains = CGFloat(numberOfMountains)

        return
            ((index
            + (((animationValue.truncatingRemainder(
                dividingBy: maxAnimationValue
            )) / maxAnimationValue))) / numberOfMountains)
        //

        // 19 +

    }

    func regenerateMountains() {

        animationValue = 0
        mountains.removeAll()

        for _ in 0..<numberOfMountains {
            let mountain = MountainConfiguration(
                maxPointsPerDepth: maxPointsPerDepth,
                depth: depth
            )
            mountains.append(mountain)
        }

    }

    func bump(_ x: CGFloat) -> CGFloat {
        CGFloat(sin(Double.pi * Double(x)))
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
    let rounded: Bool

    init(configuration: MountainConfiguration, rounded: Bool = false) {
        self.configuration = configuration
        self.rounded = rounded
    }

    func path(in rect: CGRect) -> Path {
        let ridge = configuration.ridgePoints(in: rect)
        guard ridge.count > 1 else { return Path() }

        var path = Path()
        path.move(to: ridge[0])

        if rounded {
            for i in 1..<ridge.count {
                let previous = ridge[i - 1]
                let current = ridge[i]

                let midPoint = CGPoint(
                    x: (previous.x + current.x) / 2,
                    y: (previous.y + current.y) / 2
                )

                path.addQuadCurve(
                    to: midPoint,
                    control: previous
                )
            }

            // Finish final segment
            if let last = ridge.last {
                path.addLine(to: last)
            }
        } else {
            for point in ridge.dropFirst() {
                path.addLine(to: point)
            }
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    ContentView()
}
