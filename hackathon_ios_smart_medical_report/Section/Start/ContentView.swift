//
//  ContentView.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import SwiftUI

struct ContentView: View {
    //MARK: - PROPERTIES
    
    @State private var isLoading : Bool = false
    @State private var isLogged : Bool = false
    
    @ObservedObject private var loggedUser = LoggedUser.sharedInstance
    
    //MARK: - FUNCTIONS
    
    func getProfile() {
        isLoading = true
        UserAPI.getUser { response in
            if response.success {
                
                isLogged = true
                isLoading = false
                
                
            } else {
                isLogged = false
                isLoading = false
            }
        }
    }
    
    //MARK: - BODY
    var body: some View {
        NavigationView {
            if isLoading {
                ZStack {
                    Color.customBackground.ignoresSafeArea()
                    VStack {
                        Spacer()
                        
                        Image(.logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 240, height: 128)
                        
                        Spacer()
                    }
                }
                .navigationBarBackButtonHidden()
            } else {
                if isLogged {
                    TabBarView()
                        .navigationBarBackButtonHidden()
                } else {
                    LoginView()
                        .navigationBarBackButtonHidden()
                }
            }
        }
        .onAppear {
            getProfile()
        }
        .navigationViewStyle(.stack)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    ContentView()
}
