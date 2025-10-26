//
//  TextFieldCreateCustom.swift
//  VoxBible
//
//  Created by Mohamad on 22/09/25.
//

import SwiftUI

struct TextFieldCreateCustom: View {
    //MARK: - PROPERTIES
    
    var systemName: String
    var titleString : String
    @Binding var text: String
//    @FocusState var focus: Bool
    var textFieldText : String
    var onSubmit : () -> Void
    var showKeyboardToolbar : Bool
    var autocapitalization: TextInputAutocapitalization? = .sentences
    var isSecure : Bool = false
    var keyBoardType: UIKeyboardType = .default
    var isSucess : Bool = false
    var onValidationSuccess: (() -> Void)? = nil
    var onValidationError: (() -> Void)? = nil
    var isValid: ((String) -> Bool)? = nil
    
    //MARK: - BODY
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: systemName)
                    .foregroundStyle(.customLabel)
                    .font(.subheadline)
                
                Text(titleString)
                    .foregroundStyle(.customLabel)
                    .font(.subheadline)
                
            }
            CustomTextField(
                text: $text,
                placeholder: textFieldText,
                isSecure: isSecure,
                keyboardType: keyBoardType,
                textContentType: .none,
                autocapitalization: autocapitalization,
                disableAutocorrection: true,
                submitLabel: .go,
                onSubmit: { onSubmit() },
                onValidationSuccess: onValidationSuccess,
                onPrevious: {},
                onNext: {},
                onClose: {
                    hideKeyboard()
                },
                showKeyboardToolbar: showKeyboardToolbar,
                isValid: isValid ?? { _ in true },
                isSuccess: isSucess,
                backgroundColor: .customWhite,
                textColor: .customInput,
                iconColor: .customInput,
                placeholderColor: .customPlaceholder
            )
//            .focused($focus)
//            .background(
//                RoundedRectangle(cornerRadius: 14)
//                    .stroke(.customYellow, lineWidth: focus ? 1 : 0)
//            )
        }
    }
}

