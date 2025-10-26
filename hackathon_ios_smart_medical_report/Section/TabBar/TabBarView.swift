//
//  TabBarView.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import SwiftUI

struct TabBarView: View {
    
    //MARK: - PROPERTIES
    
    //    @ObservedObject private var loggedUser = LoggedUser.sharedInstance
    
    @State private var selectedTab: Int = 0
    @State private var rotationAngle: Double = 0
    @State private var quickSpinTrigger: Bool = false
    
    private let tabbarImagesArray = [
        "house",
        "",
        "person"
    ]
    
    //MARK: - BODY
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                contentView
                customTabBar
                //                    .padding(.horizontal)
                //                    .padding(.top, 8)
            }
            .background(Color.customBackground)
            .navigationBarBackButtonHidden()
            .ignoresSafeArea(.keyboard)
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            startContinuousRotation()
        }
    }
    
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case 0: HomeView() // ⭐ Passando o binding para HomeView
        case 1: VoiceView()
        case 2: ProfileView()
        default: EmptyView()
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 40) {
            ForEach(0..<tabbarImagesArray.count, id: \.self) { index in
                if index == 1 {
                    Spacer()
                } else {
                    tabBarItem(index: index)
                }
            }
        }
        .overlay(alignment: .center, content: {
            centerTabBarItem(index: 1)
                .padding(.bottom)
        })
        .padding(.horizontal, 30)
        .padding(.top, 10)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .foregroundStyle(Color.customTabBar)
                .ignoresSafeArea()
        )
    }
    
    private func tabBarItem(index: Int) -> some View {
        let isSelected = selectedTab == index
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tabbarImagesArray[index])
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(isSelected ? .customCyan : .gray)
                    .frame(width: 25, height: 25)
                    .padding(4)
                    .background(Color.clear)
            }
            //            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    private func centerTabBarItem(index: Int) -> some View {
        let isSelected = selectedTab == index
        
        return Button {
            // Giro rápido no clique
            withAnimation(.easeInOut(duration: 0.5)) {
                quickSpinTrigger.toggle()
            }
            
            // Seleção da tab
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            ZStack {
                Image(.centerTab)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(.black)
                    .rotationEffect(.degrees(rotationAngle))
                    .rotationEffect(.degrees(quickSpinTrigger ? 360 : 0))
                    .offset(y: -10)
                
                Image(systemName: "exclamationmark.circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .customCyan : .gray)
                    .offset(y: -10)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private func startContinuousRotation() {
        withAnimation(
            Animation.linear(duration: 4.0)
                .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
}

#Preview {
    TabBarView()
}
