//
//  View+Extensions.swift
//  VoxBible
//
//  Created by Mohamad on 18/09/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    func interactiveDismiss(enabled: Bool) -> some View {
        self.modifier(InteractiveDismissModifier(isEnabled: enabled))
    }
    
    func toast(isPresented: Binding<Bool>, text: Binding<String>, isError: Bool = false) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, text: text, isError: isError))
    }
}

