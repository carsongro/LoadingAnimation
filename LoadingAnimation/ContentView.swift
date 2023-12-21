//
//  ContentView.swift
//  LoadingAnimation
//
//  Created by Carson Gross on 12/21/23.
//

import SwiftUI

extension Animation {
    static var smooth: Animation {
        Animation.timingCurve(0.5, -0.5, 0.4, 1.5)
    }
    
    static func smooth(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0.11, 0.16, 0.05, 1.53, duration: duration)
    }
}

/// https://developer.apple.com/documentation/swiftui/composing_custom_layouts_with_swiftui
struct RadialLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let radius = min(bounds.size.width, bounds.size.height) / 3.0
        
        let angle = Angle.degrees(360.0 / Double(subviews.count)).radians
        
        for (index, subview) in subviews.enumerated() {
            var point = CGPoint(x: 0, y: -radius)
                .applying(CGAffineTransform(
                    rotationAngle: angle * Double(index)))
            
            point.x += bounds.midX
            point.y += bounds.midY
            
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
}

class SmallDot : Identifiable, ObservableObject {
    let id = UUID()
    
    @Published var offset : CGSize = .zero
    @Published var color : Color = .primary
}


@Observable class BigDot : Identifiable {
    let id = UUID()
    
    var offset: CGSize = .zero
    var color: Color = .primary
    var scale: Double = 1.0
    var smallDots = [SmallDot]()
    
    init() {
        for _ in 0..<3 {
            smallDots.append(SmallDot())
        }
    }
    
    
    func randomizePositions() {
        for dot in smallDots {
            dot.offset = CGSize(width: Double.random(in: -30...30), height: Double.random(in: -30...30))
            dot.color = DotTracker.randomColor
        }
    }
    
    
    func resetPositions() {
        for dot in smallDots {
            dot.offset = .zero
            dot.color = .primary
        }
    }
    
}

@Observable class DotTracker {
    var bigDots = [BigDot]()
    
    static var colors: [Color] = [.pink, .purple, .mint, .blue, .yellow, .red, .teal, .cyan]
    static var randomColor: Color {
        colors.randomElement() ?? .blue
    }
    
    init() {
        for _ in 0..<6 {
            bigDots.append(BigDot())
        }
    }
    
    func randomizePositions() {
        for bigDot in bigDots {
            bigDot.offset = CGSize(width: Double.random(in: -20...20), height: Double.random(in: -20...20))
            bigDot.scale = 2.5
            bigDot.color = DotTracker.randomColor
            bigDot.randomizePositions()
        }
    }
    
    
    func resetPositions() {
        for bigDot in bigDots {
            bigDot.offset = .zero
            bigDot.scale = 1.0
            bigDot.color = DotTracker.randomColor
            bigDot.resetPositions()
        }
    }
}

struct LoadingView: View {
    @State private var tracker = DotTracker()
    @State private var isAnimating = false
    @State private var rotation = 0.0
    
    let rotationTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let animationTimer = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()
    
    var body: some View {
        RadialLayout {
            ForEach(tracker.bigDots) { bigDot in
                ZStack {
                    Circle()
                        .offset(bigDot.offset)
                        .foregroundColor(bigDot.color)
                        .scaleEffect(bigDot.scale)
                    ForEach(bigDot.smallDots) { smallDot in
                        Circle()
                            .offset(smallDot.offset)
                            .foregroundColor(smallDot.color)
                    }
                }
            }
        }
        .padding(68)
        .frame(width: 170, height: 170)
        .drawingGroup()
        .rotationEffect(.degrees(rotation))
        .onReceive(rotationTimer) { _ in
            withAnimation(.linear) {
                rotation += isAnimating ? 3
                : 23
            }
        }
        .onReceive(animationTimer) { _ in
            isAnimating.toggle()
        }
        .onChange(of: isAnimating) { oldValue, newValue in
            if newValue {
                withAnimation(.smooth(duration: 1.6)) {
                    tracker.randomizePositions()
                }
            } else {
                withAnimation {
                    tracker.resetPositions()
                }
            }
        }
    }
}

#Preview {
    LoadingView()
}
