//
//  ContentView.swift
//  MontainGenerator
//
//  Created by Jan Huber on 15.12.2025.
//

import SwiftUI


struct ContentView: View {
    @State private var numberOfMountains = 10

    @State private var maxPointsPerDepth = 2
    @State private var depth = 2




    var body: some View {
        VStack {

            ZStack {

                GeometryReader { geo in

                    Rectangle()
                        .fill(
                            Gradient(stops: [
                                 .init(color: Color.blue, location: 0),
                                // .init(color: Color.white, location: 0.5)
                                 ])
                        )

                /*   Gradient(stops: [
                     .init(color: Color.blue, location: 0),
                     .init(color: Color.white, location: 1)
                     ])*/

                    ForEach(0..<numberOfMountains, id: \.self) { i in

                        let mountain = Mountain(maxPointsPerDepth: maxPointsPerDepth, depth: depth)

                        let gradient = LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.blue, location: 0),
                               // .init(color: Color.white, location: 0.5)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        ZStack {
                            Color.blue
                            Color.black.opacity(CGFloat(i)/CGFloat(numberOfMountains))   // your 50% overlay base
                        }
                        .clipShape(mountain)
                        .padding(.top, (geo.size.height/Double(numberOfMountains))*Double(i))

                    }

                }

            }

            VStack {

                Slider(
                    value: Binding(
                        get: { Double(numberOfMountains) },
                        set: { numberOfMountains = Int($0.rounded()) }
                    ),
                    in: 1...20,
                    step: 1
                )

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

        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard pc.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }

        let newS = max(0, s * (1 - t))          // fade saturation to 0 (white)
        let newB = b + (1 - b) * t              // lift brightness to 1

        return Color(PlatformColor(hue: h, saturation: newS, brightness: newB, alpha: a))

        #elseif canImport(AppKit)
        // NSColor needs to be in an RGB-compatible space before extracting HSB.
        guard let rgb = PlatformColor(self).usingColorSpace(.deviceRGB) else { return self }

        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        let newS = max(0, s * (1 - t))
        let newB = b + (1 - b) * t

        return Color(PlatformColor(calibratedHue: h, saturation: newS, brightness: newB, alpha: a))
        #endif
    }
}
public extension Color {

    static func random(randomOpacity: Bool = false) -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            opacity: randomOpacity ? .random(in: 0...1) : 1
        )
    }
}

struct Mountain: Shape {

    let maxPointsPerDepth: Int
    let depth: Int

    func path(in rect: CGRect) -> Path {

        let height = rect.height
        let width = rect.width

        var path = Path()

        let startPoint = CGPoint(x: 0, y: CGFloat.random(in: 0...height))
        let endPoint = CGPoint(x: width, y: CGFloat.random(in: 0...height))

        path.move(to: startPoint)

        path.drawMontain(
            from: startPoint,
            to: endPoint,
            maxPointsPerDepth: maxPointsPerDepth,
            currentDepth: depth
        )  //

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        /*let numberOfMorePoints = Int.random(in: 0...maxPointsPerDepth)
        var morePointsX: [CGFloat] = []
        for _ in 0..<numberOfMorePoints {
            morePointsX.append(CGFloat.random(in: 0...width))
        }
        morePointsX.sort()
        
        var morePoints: [CGPoint] = []
        
        for x in morePointsX {
            morePoints.append(CGPoint.init(x: x, y: CGFloat.random(in: 0...height)))
        }
        
        for point in morePoints {
            path.addLine(to: point)
        
        }*/

        return path
    }

}

extension Path {
    mutating func drawMontain(
        from firstPoint: CGPoint,
        to lastPoint: CGPoint,
        maxPointsPerDepth: Int,
        currentDepth: Int
    ) {

        guard currentDepth > 0 else {
            addLine(to: lastPoint)
            return
        }

        let minY = min(firstPoint.y, lastPoint.y)
        let maxY = max(firstPoint.y, lastPoint.y)

        let numberOfMorePoints = maxPointsPerDepth  //Int.random(in: 0...maxPointsPerDepth)

        /*var morePointsX: [CGFloat] = []
        for _ in 0..<numberOfMorePoints {
            morePointsX.append(CGFloat.random(in: firstPoint.x...lastPoint.x))
        }
        morePointsX.sort()
        
        var morePoints: [CGPoint] = []
        
        for x in morePointsX {
            morePoints.append(CGPoint.init(x: x, y: CGFloat.random(in: minY...maxY)))
        }*/

        var morePoints: [CGPoint] = []
        for i in 1...numberOfMorePoints {
            let width = lastPoint.x - firstPoint.x
            let widthPerSegment = width / (CGFloat(numberOfMorePoints) + 1.0)
            let newX = firstPoint.x + widthPerSegment * CGFloat(i)
            morePoints.append(
                .init(x: newX, y: CGFloat.random(in: minY...maxY))
            )
        }

        if morePoints.count >= 1 {
            for i in 0...morePoints.count {
                if i == 0 {
                    drawMontain(
                        from: firstPoint,
                        to: morePoints[i],
                        maxPointsPerDepth: maxPointsPerDepth,
                        currentDepth: currentDepth - 1
                    )
                } else if i == morePoints.count {
                    drawMontain(
                        from: morePoints[i - 1],
                        to: lastPoint,
                        maxPointsPerDepth: maxPointsPerDepth,
                        currentDepth: currentDepth - 1
                    )
                } else {
                    drawMontain(
                        from: morePoints[i - 1],
                        to: morePoints[i],
                        maxPointsPerDepth: maxPointsPerDepth,
                        currentDepth: currentDepth - 1
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
