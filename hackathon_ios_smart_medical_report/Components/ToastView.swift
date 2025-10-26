//
//  ToastView.swift
//  VoxBible
//
//  Created by Mohamad on 09/09/25.
//

import SwiftUI

struct ToastView: View {
    // MARK: - PROPERTIES
    var isError: Bool
    var text: String
    
    var body: some View {
        HStack {
            Image(systemName: isError ? "xmark.seal.fill" : "checkmark.seal.fill")
                .foregroundStyle(isError ? .red : .green)
            
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.black.opacity(0.5))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - MODIFIER 
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var text: String
    var isError: Bool

    // Estados internos
    @State private var isVisible = false       // controla offset/opacity
    @State private var keepMounted = false     // mantém o view montado durante a saída
    private let animDuration: Double = 0.35
    private let yOffset: CGFloat = 120

    func body(content: Content) -> some View {
        ZStack {
            content

            if keepMounted {
                VStack {
                    Spacer()
                    ToastView(isError: isError, text: text)
                        .offset(y: isVisible ? -30 : yOffset) // sobe/ desce
                        .opacity(isVisible ? 1 : 0)         // fade junto
                        .animation(.easeInOut(duration: animDuration), value: isVisible)
                        .allowsHitTesting(false)
                        .zIndex(1)
                }
                .transition(.identity) // evita transições extras
                .onChange(of: isPresented) { newValue in
                    if newValue {
                        // ENTRA: monta e anima para cima
                        keepMounted = true
                        // pequeno defer para garantir layout antes da animação
                        DispatchQueue.main.async {
                            isVisible = true
                        }
                    } else {
                        // SAI: anima para baixo, e só então desmonta
                        isVisible = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + animDuration) {
                            // desmonta apenas se ainda não foi reapresentado
                            if !isPresented {
                                keepMounted = false
                            }
                        }
                    }
                }
                .onAppear {
                    if isPresented {
                        keepMounted = true
                        DispatchQueue.main.async { isVisible = true }
                    }
                }
            }
        }
        .onChange(of: isPresented) { newValue in
            // garante montagem imediata quando apresentar
            if newValue { keepMounted = true }
        }
    }
}
