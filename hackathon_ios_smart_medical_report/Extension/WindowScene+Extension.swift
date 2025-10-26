//
//  WindowScene+Extension.swift
//  VoxBible
//
//  Created by Mohamad on 13/10/25.
//

import UIKit

extension UIWindowScene {
    var keyWindow: UIWindow? {
        return self.windows.first(where: { $0.isKeyWindow })
    }
}
