import SwiftUI

struct AnimationView: View {
    enum RenderMode {
        case interactive
        case export
    }

    let renderMode: RenderMode

    @State private var driver: DisplayRedrawDriver?
    @State private var aspectRatio: CGFloat
    @State private var mountains: [MountainConfiguration]
    @State private var didAppearOnce = false

    @State private var musicPlayer = BackgroundMusicPlayer()

    @State var configuration: MountainsConfiguration
    @ObservedObject var engine: AnimationEngine

    init(
        configuration: MountainsConfiguration,
        engine: AnimationEngine,
        initialAspectRatio: CGFloat = 1,
        renderMode: RenderMode = .interactive
    ) {
        self.renderMode = renderMode
        _configuration = State(initialValue: configuration)
        _engine = ObservedObject(wrappedValue: engine)
        _aspectRatio = State(initialValue: initialAspectRatio)
        _mountains = State(initialValue: Self.makeInitialMountains(
            configuration: configuration,
            aspectRatio: initialAspectRatio
        ))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                mountainsView(in: geo)
            }
            .clipped()
            .onChange(of: geo.size) { _, newSize in
                aspectRatio = newSize.width / max(newSize.height, 1)
            }
            .onAppear {
                aspectRatio = geo.size.width / max(geo.size.height, 1)
                if didAppearOnce == false {
                    Task { @MainActor in
                        await Task.yield()
                        regenerateMountains()
                        didAppearOnce = true
                    }
                }

                startIfNeeded()
            }
            .onDisappear {
                driver?.stop()
                if renderMode == .interactive {
                    musicPlayer.stop()
                }
            }
            .onChange(of: configuration.maxPointsPerDepth) {
                Task { @MainActor in
                    await Task.yield()
                    regenerateMountains()
                }
            }
            .onChange(of: configuration.depth) {
                Task { @MainActor in
                    await Task.yield()
                    regenerateMountains()
                }
            }
            .onChange(of: configuration.numberOfMountains) {
                Task { @MainActor in
                    await Task.yield()
                    regenerateMountains()
                }
            }
            .onChange(of: engine.animationValue) { newValue in
                guard newValue == 0 else { return }
                Task { @MainActor in
                    await Task.yield()
                    guard mountains.isEmpty == false else { return }
                    let mountain = generateMountainConfiguration()
                    mountains.insert(mountain, at: 0)
                    mountains.removeLast()
                }
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        if renderMode == .export {
            Rectangle()
                .fill(configuration.backgroundColorForVideo)
        } else {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: configuration.backgroundGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private func mountainsView(in geo: GeometryProxy) -> some View {
        ForEach(Array(mountains.enumerated()), id: \.1.id) { index, mountain in
            let nearness = nearness(index: index)

            ZStack {
                background
                mountainOverlayColor(for: mountain, nearness: nearness)
            }
            .clipShape(
                MountainShape(configuration: mountain, rounded: configuration.rounded)
            )
            .scaleEffect(
                CGFloat(1) + pow(nearness, configuration.zoomEffect) * configuration.zoomEffect2,
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

    private func nearness(index: Int) -> CGFloat {
        let index = CGFloat(index)
        let animationValue = CGFloat(engine.animationValue)
        let numberOfMountains = CGFloat(configuration.numberOfMountains)

        return
            (index
            + ((animationValue.truncatingRemainder(dividingBy: engine.maxAnimationValue))
            / engine.maxAnimationValue)) / numberOfMountains
    }

    private func startIfNeeded() {
        guard renderMode == .interactive else { return }

        musicPlayer.play(resourceName: configuration.musicFileName)

        let newDriver = DisplayRedrawDriver { _ in
            engine.nextFrame()
        }
        driver = newDriver

        Task { @MainActor in
            await Task.yield()
            newDriver.start()
        }
    }

    @ViewBuilder
    private func mountainOverlayColor(
        for mountain: MountainConfiguration,
        nearness: CGFloat
    ) -> some View {
        switch renderMode {
        case .export:
            mountain.color.opacity(nearness)
        case .interactive:
            configuration.foregroundColor.opacity(nearness * nearness)
        }
    }

    private func regenerateMountains() {
        engine.animationValue = 0
        mountains.removeAll()
        mountains = Self.makeInitialMountains(configuration: configuration, aspectRatio: aspectRatio)
    }

    private func generateMountainConfiguration() -> MountainConfiguration {
        let seed = UInt64.random(in: UInt64.min...UInt64.max)
        return MountainConfiguration(
            maxPointsPerDepth: max(
                1,
                max(configuration.maxPointsPerDepth, Int(CGFloat(configuration.maxPointsPerDepth) * aspectRatio))
            ),
            depth: configuration.depth,
            seed: seed,
            color: configuration.mountainColor(seed: seed)
        )
    }

    private static func makeInitialMountains(
        configuration: MountainsConfiguration,
        aspectRatio: CGFloat
    ) -> [MountainConfiguration] {
        (0..<configuration.numberOfMountains).map { _ in
            let seed = UInt64.random(in: UInt64.min...UInt64.max)
            return MountainConfiguration(
                maxPointsPerDepth: max(
                    1,
                    max(
                        configuration.maxPointsPerDepth,
                        Int(CGFloat(configuration.maxPointsPerDepth) * aspectRatio)
                    )
                ),
                depth: configuration.depth,
                seed: seed,
                color: configuration.mountainColor(seed: seed)
            )
        }
    }
}
