import SwiftUI

struct MountainShape: Shape {
    let configuration: MountainConfiguration
    let rounded: Bool

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

                path.addQuadCurve(to: midPoint, control: previous)
            }

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

