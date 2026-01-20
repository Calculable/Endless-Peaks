import Combine
import CoreGraphics
import Foundation

@MainActor
final class AnimationEngine: ObservableObject {
    private let speed: CGFloat
    let maxAnimationValue = CGFloat(1)

    @Published var animationValue: CGFloat = 0

    init(speed: CGFloat) {
        self.speed = speed
    }

    func nextFrame() {
        animationValue += speed
        if animationValue >= maxAnimationValue {
            animationValue = 0
        }
    }
}

