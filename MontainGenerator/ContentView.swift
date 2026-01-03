import Foundation
import SwiftUI

private struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    fileprivate func readSize(_ onChange: @escaping (CGSize) -> Void)
        -> some View
    {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: SizeKey.self, value: geo.size)
            }
        )
        .onPreferenceChange(SizeKey.self, perform: onChange)
    }
}

@Observable
class MountainsConfiguration {
    var numberOfMountains = 10
    var maxPointsPerDepth = 3
    var depth = 2
    var speed: CGFloat = 0.01
    var zoomEffect2: CGFloat = 1.5
    var zoomEffect: CGFloat = 1.0
    var offsetEffect: CGFloat = 3
    var offsetEffect2: CGFloat = 1
    var backgroundColor1 = Color.random()
    var backgroundColor2 = Color.random()
    var backgroundColor3 = Color.white
    var foregroundColor = Color.black
    var rounded: Bool = true

    var backgroundGradient: Gradient {
        Gradient(stops: [
            .init(color: backgroundColor1, location: 0),
            .init(color: backgroundColor2, location: 0.5),
            .init(color: backgroundColor3, location: 1.0),

        ])
    }
}

struct ContentView: View {
    @State private var driver: DisplayRedrawDriver?
    @State private var animationValue: CGFloat = 0.0
    @State private var aspectRatio: CGFloat = 1
    @State var configuration = MountainsConfiguration()
    @State private var mountains = [MountainConfiguration]()
    private let maxAnimationValue = CGFloat(1)

    var background: some View {
        Rectangle()
            .fill(
                configuration.backgroundGradient
            )
    }

    var mountainsView: some View {
        GeometryReader { geo in
            ForEach(Array(mountains.enumerated()), id: \.1.id) {
                (index, mountain) in

                let nearness = nearness(index: index)

                ZStack {
                    background
                    configuration.foregroundColor.opacity(nearness * nearness)
                }
                .clipShape(
                    Mountain(
                        configuration: mountain,
                        rounded: configuration.rounded
                    )
                )
                .scaleEffect(
                    CGFloat(1) + pow(nearness, configuration.zoomEffect)
                        * configuration.zoomEffect2,
                    anchor: .top
                )
                .offset(
                    x: 0,
                    y: geo.size.height
                        * pow(nearness, configuration.offsetEffect)
                        * configuration.offsetEffect2
                )

            }
        }
    }

    var body: some View {
        VStack {
            GeometryReader { geo in

                ZStack {
                    background
                    mountainsView
                }.onChange(of: geo.size) { _, newSize in
                    aspectRatio = newSize.width / max(newSize.height, 1)
                }
            }.clipped()

            VStack {
                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(configuration.numberOfMountains) },
                            set: {
                                configuration.numberOfMountains = Int(
                                    $0.rounded()
                                )
                            }
                        ),
                        in: 1...30,
                        step: 1
                    )

                    Text(
                        "numberOfMountains: \(configuration.numberOfMountains)"
                    )

                }

                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(configuration.maxPointsPerDepth) },
                            set: {
                                configuration.maxPointsPerDepth = Int(
                                    $0.rounded()
                                )
                            }
                        ),
                        in: 1...10,
                        step: 1
                    )

                    Text(
                        "maxPointsPerDepth: \(configuration.maxPointsPerDepth)"
                    )

                }

                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(configuration.depth) },
                            set: { configuration.depth = Int($0.rounded()) }
                        ),
                        in: 1...7,
                        step: 1
                    )

                    Text("depth: \(configuration.depth)")

                }

                HStack {

                    Slider(
                        value: Binding(
                            get: { configuration.speed },
                            set: { configuration.speed = $0 }
                        ),
                        in: 0.01...1.0,
                        step: 0.01
                    )

                    Text("speed: \(configuration.speed)")

                }

                HStack {

                    Slider(
                        value: Binding(
                            get: { configuration.zoomEffect },
                            set: { configuration.zoomEffect = $0 }
                        ),
                        in: 0.01...100,
                        step: 0.01
                    )

                    Text("zoomEffect: \(configuration.zoomEffect)")

                }

                HStack {

                    Slider(
                        value: Binding(
                            get: { configuration.zoomEffect2 },
                            set: { configuration.zoomEffect2 = $0 }
                        ),
                        in: 0.01...100,
                        step: 0.01
                    )

                    Text("zoomEffect2: \(configuration.zoomEffect2)")

                }

                HStack {

                    Slider(
                        value: Binding(
                            get: { configuration.offsetEffect },
                            set: { configuration.offsetEffect = $0 }
                        ),
                        in: 0.01...100,
                        step: 0.01
                    )

                    Text("offsetEffect: \(configuration.offsetEffect)")

                }

                HStack {

                    Slider(
                        value: Binding(
                            get: { configuration.offsetEffect2 },
                            set: { configuration.offsetEffect2 = $0 }
                        ),
                        in: 0.01...100,
                        step: 0.01
                    )

                    Text("offsetEffect2: \(configuration.offsetEffect2)")

                }

                ColorPicker(
                    "Background Color 1",
                    selection: $configuration.backgroundColor1
                )
                ColorPicker(
                    "Background Color 2",
                    selection: $configuration.backgroundColor2
                )
                ColorPicker(
                    "Background Color 3",
                    selection: $configuration.backgroundColor3
                )

                Toggle("Rounded", isOn: $configuration.rounded)

            }.padding()
        }
        .onAppear {
            regenerateMountains()
            driver = DisplayRedrawDriver { t in
                animationValue += self.configuration.speed
                if animationValue >= maxAnimationValue {
                    animationValue = 0
                    let mountain = MountainConfiguration(
                        maxPointsPerDepth: max(
                            1,
                            configuration.maxPointsPerDepth * Int(aspectRatio)
                        ),
                        depth: configuration.depth
                    )
                    mountains.insert(mountain, at: 0)
                    mountains.removeLast()
                }
            }
            driver?.start()
        }
        .onDisappear {
            driver?.stop()
        }
        .onChange(of: self.configuration.maxPointsPerDepth) {
            regenerateMountains()
        }
        .onChange(of: self.configuration.depth) {
            regenerateMountains()
        }
        .onChange(of: self.configuration.numberOfMountains) {
            regenerateMountains()
        }
    }

    func nearness(index: Int) -> CGFloat {
        //von 0 bis 1

        let index = CGFloat(index)
        let animationValue = CGFloat(animationValue)
        let numberOfMountains = CGFloat(configuration.numberOfMountains)

        return
            ((index
            + (((animationValue.truncatingRemainder(
                dividingBy: maxAnimationValue
            )) / maxAnimationValue))) / numberOfMountains)

    }

    func regenerateMountains() {
        animationValue = 0
        mountains.removeAll()

        for _ in 0..<configuration.numberOfMountains {
            let mountain = MountainConfiguration(
                maxPointsPerDepth: configuration.maxPointsPerDepth,
                depth: configuration.depth
            )
            mountains.append(mountain)
        }

    }
}

struct MountainConfiguration: Identifiable {
    let maxPointsPerDepth: Int
    let depth: Int
    let seed: UInt64
    let id = UUID()

    let ridgeUnitPoints: [CGPoint]

    init(maxPointsPerDepth: Int, depth: Int, seed: UInt64? = nil) {
        self.maxPointsPerDepth = maxPointsPerDepth
        self.depth = depth
        let seed = seed ?? UInt64.random(in: UInt64.min...UInt64.max)
        self.seed = seed
        var rng = SeededGenerator(seed: seed)

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

            if i == 0 {
                result.append(contentsOf: seg)
            } else {
                result.append(contentsOf: seg.dropFirst())
            }
        }

        return result
    }
}

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
