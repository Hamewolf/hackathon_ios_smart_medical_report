//
//  Navigation+Extension.swift
//  the_box_barber_shop
//
//  Created by Mohamad on 03/09/25.
//

import SwiftUI

struct InteractiveDismissModifier: ViewModifier {
    var isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .background(InteractiveDismissEnabler(isEnabled: isEnabled))
    }
}

struct InteractiveDismissEnabler: UIViewControllerRepresentable {
    var isEnabled: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            if let navigationController = viewController.navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = isEnabled
                navigationController.interactivePopGestureRecognizer?.delegate = isEnabled ? context.coordinator : nil
            }
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let navigationController = uiViewController.navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = isEnabled
            navigationController.interactivePopGestureRecognizer?.delegate = isEnabled ? context.coordinator : nil
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
