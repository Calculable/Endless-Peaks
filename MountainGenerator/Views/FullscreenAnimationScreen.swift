import SwiftUI

struct FullscreenAnimationScreen: View {
    let configuration: MountainsConfiguration

    @StateObject private var engine: AnimationEngine
    @State private var showsChrome = false

    init(configuration: MountainsConfiguration) {
        self.configuration = configuration
        _engine = StateObject(wrappedValue: AnimationEngine(speed: configuration.speed))
    }

    var body: some View {
        AnimationView(configuration: configuration, engine: engine)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showsChrome.toggle()
                }
            }
            .navigationBarBackButtonHidden(!showsChrome)
            #if os(macOS)
                .toolbarVisibility(
                    showsChrome ? .visible : .hidden,
                    for: .windowToolbar
                )
            #else
                .toolbarVisibility(
                    showsChrome ? .visible : .hidden,
                    for: .navigationBar
                )
            #endif
            #if os(iOS) || os(tvOS) || os(visionOS)
                .statusBarHidden(!showsChrome)
            #endif
    }
}
