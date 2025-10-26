//
//  LoadingView.swift
//  VoxBible
//
//  Created by Mohamad on 09/09/25.
//

import SwiftUI

struct LoadingView: View {
    
    //MARK: - PROPERTY -

    @Binding var isLoading: Bool
    @State private var trimEnd = 0.6
    @State private var animate = false
    
    //MARK: - BODY -

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    
                    Color.black.opacity(0.7).ignoresSafeArea()
                    
                    Circle()
                        .trim(from: 0.0, to: trimEnd)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 7,lineCap: .round,lineJoin:.round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(Angle(degrees: animate ? 270 + 360 : 270))
                        .onAppear {
                            trimEnd = 0
                            animate = true
                        }
                        .onDisappear {
                            trimEnd = 0.6
                            animate = false
                        }
                        .animation(.easeIn(duration: 1.5).repeatForever(autoreverses: true), value: trimEnd)
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animate)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: isLoading)
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(isLoading: .constant(true))
        LoadingView(isLoading: .constant(false))
    }
}
