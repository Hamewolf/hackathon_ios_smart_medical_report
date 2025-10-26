//
//  LoginView.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import SwiftUI

struct LoginView: View {
    //MARK: - PROPERTIES
    
    @State private var nameString : String = ""
    @State private var passwordString : String = ""
    
    @State private var isNavigate : Bool = false
    @State private var isLoading : Bool = false
    
    //Toast
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isErrorToast: Bool = false
    
    //MARK: - FUNCTIONS
    
    func login() {
        isLoading = true
        
        let params: [String: Any] = [
            "login" : nameString,
            "password": passwordString
        ]
        
        UserAPI.signIn(params: params) { response in
            isLoading = false
            if response.success {
                isLoading = true
                UserAPI.getUser { userResponse in
                    isLoading = false
                    if userResponse.success {
                       isNavigate = true
                    } else {
                        isErrorToast = true
                        Helper.showToast(isPresented: $showToast, text: $toastMessage, response.erroMessage, isError: isErrorToast)
                    }
                }
            } else {
                isErrorToast = true
                Helper.showToast(isPresented: $showToast, text: $toastMessage, response.erroMessage, isError: isErrorToast)
            }
        }
    }
    
    //MARK: - BODY
    var body: some View {
        NavigationStack {
            ZStack {
                
                NavigationLink(destination: TabBarView(), isActive: $isNavigate) {
                    EmptyView()
                }
                
                Color.customBackground.ignoresSafeArea()
                mainStruct()
                
                LoadingView(isLoading: $isLoading)
            }
            .toast(isPresented: $showToast, text: $toastMessage, isError: isErrorToast)
        }
    }
    
    //MARK: mainStruct
    @ViewBuilder
    func mainStruct() -> some View {
        VStack(spacing: 30){
            Spacer()
            topStruct()
            enterStruct()
            buttonStruct()
            Spacer()
        }
        .padding(.horizontal)
    }
    
    //MARK: topStruct
    @ViewBuilder
    func topStruct() -> some View {
        VStack{
            Image(.logo)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
            Text("Smart Medical Report")
                .font(.title2)
                .foregroundStyle(.customLabel)
                .bold()
            
            Text("Sistema de Laudos Médicos com IA")
                .font(.title3)
                .foregroundStyle(.customSubtitle)
                .fontWeight(.semibold)
        }
    }
    
    //MARK: enterStruct
    @ViewBuilder
    func enterStruct() -> some View {
        VStack(spacing: 20){
            TextFieldCreateCustom(systemName: "envelope", titleString: "Nome", text: $nameString, textFieldText: "Digite aqui", onSubmit: {
                //
            }, showKeyboardToolbar: true)
            
            TextFieldCreateCustom(systemName: "key", titleString: "Senha", text: $passwordString, textFieldText: "Digite aqui", onSubmit: {
                //
            }, showKeyboardToolbar: false, isSecure: true)
        }
    }
    
    //MARK: buttonStruct
    @ViewBuilder
    func buttonStruct() -> some View {
        VStack{
            Button {
                login()
            } label: {
                Text("Entrar")
                    .foregroundStyle(.customWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.customMediumBlue)
                    )
            }
            
            Text("Esqueceu sua senha?")
                .underline()
                .foregroundStyle(.customMediumBlue)
        }
    }
}

#Preview {
    LoginView()
}
