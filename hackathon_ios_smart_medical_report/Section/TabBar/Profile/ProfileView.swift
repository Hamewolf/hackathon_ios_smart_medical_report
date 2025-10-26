//
//  ProfileView.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import SwiftUI

struct ProfileView: View {
    //MARK: - PROPERTIES
    
    @State private var currentPassword : String = ""
    @State private var newPassword : String = ""
    @State private var confirmPassword : String = ""
    
    @ObservedObject private var loggedUser = LoggedUser.sharedInstance
    
    //MARK: - FUNCTION
    
    private func logoutAction() {
        let preferences = UserDefaults.standard
        preferences.removeObject(forKey: PreferenceKeys.token.rawValue)
        preferences.removeObject(forKey: PreferenceKeys.resfreshToken.rawValue)
        LoggedUser.clear()
        
        resetToSplashView()
    }
    
    func resetToSplashView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: ContentView())
            window.makeKeyAndVisible()
        }
    }
    
    //MARK: - BODY
    var body: some View {
        ZStack {
            Color.customBackground.ignoresSafeArea()
            ScrollView {
                mainStrucr()
            }
        }
    }
    //MARK: mainStrucr
    @ViewBuilder
    func mainStrucr() -> some View {
        VStack(alignment: .leading, spacing: 15){
            topStruct()
            
            Rectangle()
                .frame(height: 0.5)
            
            textFieldsStructs()
            
            buttonStruct()
        }
        .padding(.horizontal)
    }
    
    //MARK: topStruct
    @ViewBuilder
    func topStruct() -> some View {
        VStack(alignment: .leading){
            HStack {
                VStack(alignment: .leading){
                    Text(loggedUser.user?.name ?? "")
                        .font(.title)
                        .foregroundStyle(.customLabel)
                        .bold()
                    
                    let crmDigits = (loggedUser.user?.professional_registration ?? "").filter { $0.isNumber }
                    Text("CRM: \(crmDigits)")
                        .font(.subheadline)
                        .foregroundStyle(.customLabel)
                }
                Spacer()
                
                Button {
                    
                } label: {
                    HStack {
                        Image(systemName: "iphone.and.arrow.right.outward")
                        
                        Text("Sair")
                    }
                    .foregroundStyle(.customRed)
                    .font(.headline)
                }
            }
        }
    }
    
    //MARK: textFieldsStructs
    @ViewBuilder
    func textFieldsStructs() -> some View {
        VStack(spacing: 20){
            TextFieldCreateCustom(systemName: "key", titleString: "Senha", text: $currentPassword, textFieldText: "Digite aqui", onSubmit: {
                //
            }, showKeyboardToolbar: true, isSecure: true)
            
            TextFieldCreateCustom(systemName: "key", titleString: "Nova senha", text: $currentPassword, textFieldText: "Digite aqui", onSubmit: {
                //
            }, showKeyboardToolbar: false, isSecure: true)
            
            TextFieldCreateCustom(systemName: "key", titleString: "Confirmar senha", text: $currentPassword, textFieldText: "Digite aqui", onSubmit: {
                //
            }, showKeyboardToolbar: false, isSecure: true)
        }
    }
    
    //MARK: buttonStruct
    @ViewBuilder
    func buttonStruct() -> some View {
        Button {
            
        } label: {
            Text("Atualizar")
                .foregroundStyle(.customWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.customDarkBlue)
                )
                .padding(.vertical)
        }
    }
}

#Preview {
    ProfileView()
}
