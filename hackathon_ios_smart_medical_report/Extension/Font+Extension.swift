//
//  Font+Extension.swift
//  estacao_do_olho
//
//  Created by Mohamad on 10/09/25.
//

import SwiftUI

enum FontType: String, CaseIterable {
    
    //MARK: Inter
    case boldInter = "Inter-Bold"
    case lightInter = "Inter-Light"
    case regularInter = "Inter-Regular"
    case semiBoldInter = "Inter-SemiBold"
    case mediumInter = "Inter-Medium"
}

extension Font {
    static func defaultFont(size: CGFloat, type: FontType) -> Font {
        return Font.custom(type.rawValue, size: size)
    }
}
