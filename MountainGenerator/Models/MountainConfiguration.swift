import CoreGraphics
import SwiftUI

struct MountainConfiguration: Identifiable {
    let maxPointsPerDepth: Int
    let depth: Int
    let seed: UInt64
    let color: Color
    let id = UUID()

    let ridgeUnitPoints: [CGPoint]

    init(
        maxPointsPerDepth: Int,
        depth: Int,
        seed: UInt64? = nil,
        color: Color = .black
    ) {
        self.maxPointsPerDepth = maxPointsPerDepth
        self.depth = depth
        let seed = seed ?? UInt64.random(in: UInt64.min...UInt64.max)
        self.seed = seed
        self.color = color

        var rng = SeededGenerator(seed: seed)

        let start = CGPoint(
            x: 0.0,
            y: CGFloat.random(in: 0.0...1.0, using: &rng)
        )
        let end = CGPoint(
            x: 1.0,
            y: CGFloat.random(in: 0.0...1.0, using: &rng)
        )

        self.ridgeUnitPoints = Self.buildSegmentPoints(
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

        for i in 1...count {
            let x = a.x + CGFloat(i) * step
            let randomY = CGFloat.random(in: 0.0...1.0, using: &rng)
            let y = minY + (maxY - minY) * randomY
            mids.append(CGPoint(x: x, y: y))
        }

        var result: [CGPoint] = [a]

        let subMaxPoints = max(1, maxPointsPerDepth - 1)
        let nextDepth = currentDepth - 1

        var last = a
        for mid in mids {
            result.append(contentsOf: buildSegmentPoints(
                from: last,
                to: mid,
                maxPointsPerDepth: subMaxPoints,
                currentDepth: nextDepth,
                rng: &rng
            ).dropFirst())
            last = mid
        }

        result.append(contentsOf: buildSegmentPoints(
            from: last,
            to: b,
            maxPointsPerDepth: subMaxPoints,
            currentDepth: nextDepth,
            rng: &rng
        ).dropFirst())

        return result
    }
}

