//
//  Helper.swift
//  VoxBible
//
//  Created by Mohamad on 09/09/25.
//

import SwiftUI

class Helper {
    fileprivate init() {}

    static func showToast(
        isPresented: Binding<Bool>,
        text: Binding<String>,
        _ message: some StringProtocol,
        isError: Bool = false
    ) {
        text.wrappedValue = String(message)
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented.wrappedValue = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented.wrappedValue = false
            }
        }
    }
}

