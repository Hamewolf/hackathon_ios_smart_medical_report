//
//  CustomTextField.swift
//  VoxBible
//
//  Created by Mohamad on 11/09/25.
//

import SwiftUI
import UIKit

// Modo de validação
enum ValidationMode {
    case none          // usa o closure isValid
    case emailBasic    // exige não vazio + contém "@" + contém ".com"
}

struct CustomTextField: View {
    // MARK: - Bindings
    @Binding var text: String
    @FocusState private var isFocused: Bool

    // MARK: - Appearance & Behavior
    var placeholder: String
    var systemImage: String? = nil
    var isLeding: Bool = true
    var isSecure: Bool = false

    // Text input configuration
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization? = .sentences
    var disableAutocorrection: Bool = false

    // Submit/return key
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    // Validation callbacks
    var onValidationSuccess: (() -> Void)? = nil

    // Keyboard toolbar actions
    var onPrevious: (() -> Void)? = nil
    var onNext:     (() -> Void)? = nil
    var onClose:    (() -> Void)? = nil
    
    var showKeyboardToolbar: Bool = true

    // Validation (controls border color)
    var isValid: (String) -> Bool = { _ in true }
    var validationMode: ValidationMode = .none

    // Success state (overrides error/normal when true)
    var isSuccess: Bool = false

    // Tracks last known validation state to prevent duplicate callbacks
    @State private var lastIsValid: Bool? = nil

    // Layout & style
    var height: CGFloat = 52
    var cornerRadius: CGFloat = 14
    var backgroundOpacity: Double = 0.08
    var borderNormal: Color = .customBorder
    var borderError: Color = .customRed
    var borderSuccess: Color = .customGreen
    var iconOpacity: Double = 0.8

    // === Extra customizables (all have defaults; only apply when passed) ===
    // Typography
    var font: Font = .body
    var placeholderFont: Font? = nil // if nil, inherits from TextField font
    var textAlignment: TextAlignment = .leading

    // Icon
    var iconSize: CGFloat = 16

    // Layout
    var contentSpacing: CGFloat = 10
    var contentInsets: EdgeInsets = EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
    var frameWidth: CGFloat? = nil // if nil, no explicit width is applied

    // Border
    var borderLineWidth: CGFloat = 1

    // Shadow (disabled by default if radius == 0)
    var shadowColor: Color = .clear
    var shadowRadius: CGFloat = 0
    var shadowX: CGFloat = 0
    var shadowY: CGFloat = 0

    // New customizable colors
    var backgroundColor: Color = .customWhite
    var textColor: Color = .customInput
    var iconColor: Color = .customInput
    var placeholderColor: Color = .customPlaceholder

    // Secure toggle (only used when isSecure == true)
    @State private var showSecureText: Bool = false

    // MARK: - Validation helper
    private func isFieldValid(_ value: String) -> Bool {
        switch validationMode {
        case .none:
            return isValid(value)
        case .emailBasic:
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            // válido SOMENTE se não vazio, contém "@" e ".com"
            return !trimmed.isEmpty && trimmed.contains("@") && trimmed.contains(".com")
        }
    }

    var body: some View {
        HStack(spacing: contentSpacing) {
            if let systemImage {
                if isLeding {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSize))
                        .foregroundStyle(iconColor.opacity(iconOpacity))
                }
            }

            inputField
            
            if let systemImage {
                if !isLeding {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSize))
                        .foregroundStyle(iconColor.opacity(iconOpacity))
                }
            }
        }
        .padding(contentInsets)
        .frame(width: frameWidth, height: height)
        .background(
            backgroundColor.opacity(backgroundOpacity),
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    (isSuccess ? borderSuccess : (isFieldValid(text) ? borderNormal : borderError)),
                    lineWidth: borderLineWidth
                )
        )
        .shadow(color: shadowColor, radius: shadowRadius, x: shadowX, y: shadowY)
        .onChange(of: text) { _ in
            handleValidationCallbacks()
        }
        .onChange(of: isFocused) { newValue in
            // When focus is lost, re-emit if needed
            if newValue == false {
                handleValidationCallbacks()
            }
        }
        .onAppear {
            // Initialize validation state
            handleValidationCallbacks()
        }
#if !os(visionOS)
        .toolbar {
            if showKeyboardToolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    // Right side: close keyboard
                    Button {
                        if let onClose {
                            onClose()
                        } else {
                            dismissKeyboard()
                        }
                    } label: {
                        Text("Fechar")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Fechar teclado")
                }
            }
        }
#endif
    }

    @ViewBuilder
    private var inputField: some View {
        if isSecure {
            HStack(spacing: 8) {
                Group {
                    if showSecureText {
                        TextField(
                            "",
                            text: $text,
                            prompt: {
                                var t = Text(placeholder).foregroundColor(placeholderColor)
                                if let pf = placeholderFont { return t.font(pf) }
                                return t
                            }()
                        )
                        .foregroundColor(textColor)
                        .font(font)
                        .multilineTextAlignment(textAlignment)
                        .focused($isFocused)
                    } else {
                        SecureField(
                            "",
                            text: $text,
                            prompt: {
                                var t = Text(placeholder).foregroundColor(placeholderColor)
                                if let pf = placeholderFont { return t.font(pf) }
                                return t
                            }()
                        )
                        .foregroundColor(textColor)
                        .font(font)
                        .multilineTextAlignment(textAlignment)
                        .focused($isFocused)
                    }
                }
                .textFieldModifiers(
                    keyboardType: keyboardType,
                    textContentType: textContentType,
                    autocapitalization: autocapitalization,
                    disableAutocorrection: disableAutocorrection,
                    submitLabel: submitLabel,
                    onSubmit: onSubmit
                )

                Button(action: { showSecureText.toggle() }) {
                    Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: iconSize))
                        .foregroundStyle(iconColor.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showSecureText ? "Hide password" : "Show password")
            }
        } else {
            TextField(
                "",
                text: $text,
                prompt: {
                    var t = Text(placeholder).foregroundColor(placeholderColor)
                    if let pf = placeholderFont { return t.font(pf) }
                    return t
                }()
            )
            .foregroundColor(textColor)
            .font(font)
            .multilineTextAlignment(textAlignment)
            .focused($isFocused)
            .textFieldModifiers(
                keyboardType: keyboardType,
                textContentType: textContentType,
                autocapitalization: autocapitalization,
                disableAutocorrection: disableAutocorrection,
                submitLabel: submitLabel,
                onSubmit: onSubmit
            )
        }
    }

    // Emits success/error callbacks when validation state changes
    private func handleValidationCallbacks() {
        // If isSuccess is true, prefer success state regardless of validation
        let currentValid = isSuccess ? true : isFieldValid(text)
        if lastIsValid != currentValid {
            lastIsValid = currentValid
            if currentValid {
                onValidationSuccess?()
            }
        }
    }

    // Dismiss keyboard helper (used when onClose is not provided)
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Modifier for shared TextField/SecureField configuration
private extension View {
    @ViewBuilder
    func textFieldModifiers(
        keyboardType: UIKeyboardType,
        textContentType: UITextContentType?,
        autocapitalization: TextInputAutocapitalization?,
        disableAutocorrection: Bool,
        submitLabel: SubmitLabel,
        onSubmit: (() -> Void)?
    ) -> some View {
        self
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(disableAutocorrection)
            .submitLabel(submitLabel)
            .applyIf(textContentType != nil) { view in
                view.textContentType(textContentType!)
            }
            .onSubmit { onSubmit?() }
    }

    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 16) {
            // Email com validação básica (vazio / sem @ / sem .com -> borda vermelha), exibe sucesso (verde) se isSuccess true
            StatefulPreviewWrapper("") { binding in
                CustomTextField(
                    text: binding,
                    placeholder: "E-mail",
                    systemImage: "envelope.fill",
                    isLeding: true,
                    isSecure: false,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never,
                    disableAutocorrection: true,
                    submitLabel: .next,
                    onSubmit: { print("Next from email") },
                    onValidationSuccess: { print("Email valid") }, onPrevious: {},
                    onNext: {},
                    onClose: {},
                    validationMode: .emailBasic,
                    isSuccess: true,
                    backgroundColor: .blue,
                    textColor: .yellow,
                    iconColor: .orange,
                    placeholderColor: .gray
                )
            }

            // Senha (usa o closure isValid padrão ou personalizado)
            StatefulPreviewWrapper("") { binding in
                CustomTextField(
                    text: binding,
                    placeholder: "Senha",
                    systemImage: "lock.fill",
                    isSecure: true,
                    textContentType: .password,
                    autocapitalization: .never,
                    disableAutocorrection: true,
                    submitLabel: .go,
                    onSubmit: { print("Login tap") },
                    onNext: {},
                    onClose: {},
                    isValid: { !$0.isEmpty },
                    backgroundColor: .blue,
                    textColor: .yellow,
                    iconColor: .orange,
                    placeholderColor: .gray
                )
            }
        }
        .padding()
    }
}

/// Helper for previews that need a @Binding
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View { content($value) }
}

