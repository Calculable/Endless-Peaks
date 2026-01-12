import Foundation
import SwiftUI
internal import Combine

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

    init(
        numberOfMountains: Int = 10,
        maxPointsPerDepth: Int = 3,
        depth: Int = 2,
        speed: CGFloat = 0.01,
        zoomEffect2: CGFloat = 1.5,
        zoomEffect: CGFloat = 1.0,
        offsetEffect: CGFloat = 3,
        offsetEffect2: CGFloat = 1,
        backgroundColor1: Color = Color.random(),
        backgroundColor2: Color = Color.random(),
        backgroundColor3: SwiftUICore.Color = Color.white,
        foregroundColor: SwiftUICore.Color = Color.black,
        rounded: Bool = true
    ) {
        self.numberOfMountains = numberOfMountains
        self.maxPointsPerDepth = maxPointsPerDepth
        self.depth = depth
        self.speed = speed
        self.zoomEffect2 = zoomEffect2
        self.zoomEffect = zoomEffect
        self.offsetEffect = offsetEffect
        self.offsetEffect2 = offsetEffect2
        self.backgroundColor1 = backgroundColor1
        self.backgroundColor2 = backgroundColor2
        self.backgroundColor3 = backgroundColor3
        self.foregroundColor = foregroundColor
        self.rounded = rounded
    }

    static let appenzell = MountainsConfiguration(
        numberOfMountains: 10,
        maxPointsPerDepth: 1,
        depth: 2,
        speed: 0.005,
        zoomEffect2: 4.22,
        zoomEffect: 2.69,
        offsetEffect: 10.0,
        offsetEffect2: 10.0,
        backgroundColor1: Color.init(hex: "#089EFFFF"),
        backgroundColor2: Color.init(hex: "#C2FF3EFF"),
        backgroundColor3: Color.init(hex: "#FEFFFFFF"),
        foregroundColor: Color.black,
        rounded: true
    )

    static let yosemite = MountainsConfiguration(
        numberOfMountains: 10,
        maxPointsPerDepth: 1,
        depth: 7,
        speed: 0.005,
        zoomEffect2: 2.8899999999999997,
        zoomEffect: 5.8,
        offsetEffect: 10.0,
        offsetEffect2: 10.0,
        backgroundColor1: Color.init(hex: "#29353FFF"),
        backgroundColor2: Color.init(hex: "#8D9FA6FF"),
        backgroundColor3: Color.init(hex: "#0D0B01FF"),
        foregroundColor: Color.black,
        rounded: false
    )

    static let dolomites = MountainsConfiguration(
        numberOfMountains: 4,
        maxPointsPerDepth: 3,
        depth: 4,
        speed: 0.0025,
        zoomEffect2: 2.8899999999999997,
        zoomEffect: 4.22,
        offsetEffect: 10.0,
        offsetEffect2: 10.0,
        backgroundColor1: Color.init(hex: "#102225FF"),
        backgroundColor2: Color.init(hex: "#BFBFB9FF"),
        backgroundColor3: Color.init(hex: "#8C8B88FF"),
        foregroundColor: Color.black,
        rounded: false
    )

    static let zhangjiajie = MountainsConfiguration(
        numberOfMountains: 23,
        maxPointsPerDepth: 7,
        depth: 2,
        speed: 0.005,
        zoomEffect2: 2.8899999999999997,
        zoomEffect: 4.22,
        offsetEffect: 10.0,
        offsetEffect2: 10.0,
        backgroundColor1: Color.init(hex: "#F2AC85FF"),
        backgroundColor2: Color.init(hex: "#83A605FF"),
        backgroundColor3: Color.init(hex: "#5A7304FF"),
        foregroundColor: Color.black,
        rounded: true
    )

    static let torresDelPaine = MountainsConfiguration(
        numberOfMountains: 7,
        maxPointsPerDepth: 8,
        depth: 2,
        speed: 0.005,
        zoomEffect2: 2.8899999999999997,
        zoomEffect: 4.22,
        offsetEffect: 10.0,
        offsetEffect2: 10.0,
        backgroundColor1: Color.init(hex: "#5E6573FF"),
        backgroundColor2: Color.init(hex: "#F2984BFF"),
        backgroundColor3: Color.init(hex: "#F2845CFF"),
        foregroundColor: Color.black,
        rounded: false
    )

    static let scottishHighlands = MountainsConfiguration(
        numberOfMountains: 7,
        maxPointsPerDepth: 3,
        depth: 2,
        speed: 0.005,
        zoomEffect2: 0.37,
        zoomEffect: 2.3,
        offsetEffect: 10.0,
        offsetEffect2: 10.0,
        backgroundColor1: Color.init(hex: "#A68D9CFF"),
        backgroundColor2: Color.init(hex: "#F2CC88FF"),
        backgroundColor3: Color.init(hex: "#898C2AFF"),
        foregroundColor: Color.black,
        rounded: true
    )

    static let tassiliNAjjer = MountainsConfiguration(
        numberOfMountains: 6,
        maxPointsPerDepth: 3,
        depth: 5,
        speed: 0.005,
        zoomEffect2: 1.29,
        zoomEffect: 5.1499999999999995,
        offsetEffect: 10.0,
        offsetEffect2: 10.0,
        backgroundColor1: Color.init(hex: "#250303FF"),
        backgroundColor2: Color.init(hex: "#E32413FF"),
        backgroundColor3: Color.init(hex: "#89A1B2FF"),
        foregroundColor: Color.black,
        rounded: true
    )

    static let himalaya = MountainsConfiguration(
        numberOfMountains: 16,
        maxPointsPerDepth: 4,
        depth: 4,
        speed: 0.004,
        zoomEffect2: 5.03,
        zoomEffect: 24.900000000000002,
        offsetEffect: 10.0,
        offsetEffect2: 10.0,
        backgroundColor1: Color.init(hex: "#224459FF"),
        backgroundColor2: Color.init(hex: "#95C6D9FF"),
        backgroundColor3: Color.init(hex: "#AFE8FFFF"),
        foregroundColor: Color.black,
        rounded: true
    )

    static let background = MountainsConfiguration(
        numberOfMountains: 4,
        maxPointsPerDepth: 1,
        depth: 2,
        speed: 0.001,
        zoomEffect2: 4.22,
        zoomEffect: 2.69,
        offsetEffect: 3.13,
        offsetEffect2: 0.59,
        backgroundColor1: Color.init(hex: "#FEFFFFFF"),
        backgroundColor2: Color.init(hex: "#FEFFFFFF"),
        backgroundColor3: Color.init(hex: "#FEFFFFFF"),
        foregroundColor: Color.black,
        rounded: true
    )

}

struct ContentView: View {
    var body: some View {
        FancyOptionPickerScreen()
    }
}

@MainActor
final class AnimationEngine: ObservableObject {

    private let speed: CGFloat
    let maxAnimationValue = CGFloat(1)
    @Published var animationValue: CGFloat = 0.0

    init(speed: CGFloat) {
        self.speed = speed
        print("init engine")
    }

    func nextFrame() {
        print("next frame. Current animationValue \(animationValue)")
        animationValue += speed
        print("animationValue is now \(animationValue)")

        if animationValue >= maxAnimationValue {
            animationValue = 0
        }
    }
}



struct AnimationView: View {
    @State private var driver: DisplayRedrawDriver?
    @State private var aspectRatio: CGFloat = 1
    @State var configuration = MountainsConfiguration.tassiliNAjjer
    @State private var mountains = [MountainConfiguration]()
    @State private var didAppearOnce = false

    @StateObject var engine: AnimationEngine

    init(
        configuration: MountainsConfiguration = .tassiliNAjjer,
        engine: AnimationEngine
    ) {
        print("init animation view")
        _driver = State(initialValue: nil)
        _aspectRatio = State(initialValue: 1)
        _configuration = State(initialValue: configuration)
        _mountains = State(initialValue: [])

        _engine = StateObject(wrappedValue: engine)

        regenerateMountains()

    }



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

    var configurationView: some View {
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

            Button("Print configuration") {
                print(
                    "MountainsConfiguration(numberOfMountains: \(configuration.numberOfMountains), maxPointsPerDepth: \(configuration.maxPointsPerDepth), depth: \(configuration.depth), speed: \(configuration.speed), zoomEffect2: \(configuration.zoomEffect2), zoomEffect: \(configuration.zoomEffect), offsetEffect: \(configuration.offsetEffect), offsetEffect2: \(configuration.offsetEffect2), backgroundColor1: Color.init(hex: \"\(configuration.backgroundColor1.toHex()!)\"), backgroundColor2: Color.init(hex: \"\(configuration.backgroundColor2.toHex()!)\"), backgroundColor3: Color.init(hex: \"\(configuration.backgroundColor3.toHex()!)\"), foregroundColor: Color.black, rounded: \(configuration.rounded ? "true" : "false"))"
                )
            }

        }.padding()
    }

    var body: some View {
        GeometryReader { geo in
            VStack {

                ZStack {
                    background
                    mountainsView
                }.onChange(of: geo.size) { _, newSize in
                    aspectRatio = newSize.width / max(newSize.height, 1)
                }

               // configurationView

            }.clipped()
                .onAppear {
                    print("on appear")
                    aspectRatio = geo.size.width / max(geo.size.height, 1)
                    if didAppearOnce == false {
                        regenerateMountains()
                        didAppearOnce = true
                    }

                    //print(aspectRatio)
                    //regenerateMountains()
                    /*driver = DisplayRedrawDriver { t in
                        engine.nextFrame()
                    }
                    driver?.start()*/

                }
                .onDisappear {
                    //driver?.stop()
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
                .onChange(of: self.engine.animationValue) { newValue in
                    print("new animation value: \(newValue)")
                    if newValue == 0 {
                        let mountain = generateMountainConfiguration()
                        mountains.insert(mountain, at: 0)
                        mountains.removeLast()
                    }
                }

        }

    }

    func nearness(index: Int) -> CGFloat {
        //von 0 bis 1

        let index = CGFloat(index)
        let animationValue = CGFloat(self.engine.animationValue)
        let numberOfMountains = CGFloat(configuration.numberOfMountains)

        return
            ((index
            + (((animationValue.truncatingRemainder(
                dividingBy: self.engine.maxAnimationValue
            )) / self.engine.maxAnimationValue))) / numberOfMountains)

    }

    func regenerateMountains() {
        print("regenerate mountains")
        self.engine.animationValue = 0
        mountains.removeAll()

        for _ in 0..<configuration.numberOfMountains {
            let mountain = generateMountainConfiguration()

            mountains.append(mountain)
        }

    }

    func generateMountainConfiguration() -> MountainConfiguration {
        return MountainConfiguration(
            maxPointsPerDepth: max(
                1,
                max(configuration.maxPointsPerDepth,  Int(CGFloat(configuration.maxPointsPerDepth) * aspectRatio))
            ),
            depth: configuration.depth
        )
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
