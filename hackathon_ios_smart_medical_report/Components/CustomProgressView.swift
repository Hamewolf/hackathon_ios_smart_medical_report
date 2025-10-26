//
//  CustomProgressView.swift
//  VoxBible
//
//  Created by Mohamad on 20/10/25.
//

import SwiftUI

struct CustomProgressView: View {
    
    @State private var trimEnd: CGFloat = 0.6
    @State private var isAnimatingTrim = false
    @State private var rotation: Angle = .degrees(0)
    
    var width: CGFloat = 40
    var height: CGFloat = 40
    
    var body: some View {
        Circle()
            .trim(from: 0.0, to: trimEnd)
            .stroke(.blue, style: StrokeStyle(lineWidth: 2,lineCap: .round,lineJoin:.round))
            .frame(width: width, height: height)
            .rotationEffect(.degrees(270) + rotation)
            .onAppear {
                // Start trim pulsing (optional breathing effect)
                trimEnd = 0.2
                isAnimatingTrim = true

                // Start continuous rotation in the same direction
                rotation = .degrees(360)
            }
            .onDisappear {
                // Reset states
                trimEnd = 0.6
                isAnimatingTrim = false
                rotation = .degrees(0)
            }
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimatingTrim)
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotation)
    }
}

#Preview {
    CustomProgressView()
}
