//
//  HomeView.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import SwiftUI

struct HomeView: View {
    //MARK: - PROPERTIES
    
    @State private var searchTF : String = ""
    @State private var isLoading : Bool = false
    @State private var patients : [Patient] = []
    
    // Filtered patients by name or CPF (with/without mask)
    private var filteredPatients: [Patient] {
        // If search is empty, return full list
        let query = searchTF.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return patients }
        let lower = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
        let queryDigits = query.filter { $0.isNumber }
        return patients.filter { p in
            // Name match (case/diacritic insensitive)
            let name = p.full_name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
            let nameMatches = name.contains(lower)
            // CPF match: compare digits-only
            let cpfDigits = p.tax_id.filter { $0.isNumber }
            let cpfMatches = !queryDigits.isEmpty && cpfDigits.contains(queryDigits)
            return nameMatches || cpfMatches
        }
    }
    
    // Placeholder items shown while loading
    private let placeholderPatients: [Patient] = Array(repeating: Patient(), count: 6)
    
    //Toast
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isErrorToast: Bool = false
    
    //MARK: - FUNCTIONS
    
    func listPatient() {
        isLoading = true
        
        UserAPI.listPatient { response in
            isLoading = false
            if response.success {
                patients = response.patients
            } else {
                isErrorToast = true
                Helper.showToast(isPresented: $showToast, text: $toastMessage, response.erroMessage, isError: isErrorToast)
            }
        }
    }
    
    /// Calculates age from a birth date string in format "YYYY-MM-DD" relative to the current date.
    func calculateAge(from birthDateString: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let birthDate = formatter.date(from: birthDateString) else {
            return "-"
        }
        let now = Date()
        let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: now)
        let years = ageComponents.year ?? 0
        return String(years)
    }
    
    //MARK: - BODY
    var body: some View {
        ZStack {
            Color.customBackground.ignoresSafeArea()
            mainStrucr()
            
        }
        .toast(isPresented: $showToast, text: $toastMessage, isError: isErrorToast)
        .onAppear {
            listPatient()
        }
    }
    
    //MARK: mainStrucr
    @ViewBuilder
    func mainStrucr() -> some View {
        VStack(alignment: .leading){
            topStruct()
            
            ScrollView(.vertical, showsIndicators: false){
                VStack(spacing: 16){
                    ForEach(isLoading ? placeholderPatients : filteredPatients) { item in
                        NavigationLink {
                            PatientDetailView(patientId: item.id)
                        } label: {
                            cellPatientStruct(
                                name: item.full_name,
                                documment: item.tax_id,
                                age: calculateAge(from: item.birth_date),
                                gender: String(item.gender.prefix(1))
                            )
                            .redacted(reason: isLoading ? .placeholder : [])
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    //MARK: topStruct
    @ViewBuilder
    func topStruct() -> some View {
        Text("Lista de,")
            .font(.title3)
            .foregroundStyle(.customLabel)
        
        Text("Pacientes")
            .font(.title2)
            .foregroundStyle(.customLabel)
            .bold()
        
        CustomTextField(
            text: $searchTF,
            placeholder: "Pesquisar",
            systemImage: "magnifyingglass",
            isLeding: false,
            isSecure: false,
            keyboardType: .default,
            textContentType: .none,
            autocapitalization: .never,
            disableAutocorrection: true,
            submitLabel: .go,
            onPrevious: {},
            onNext: {},
            onClose: {
                hideKeyboard()
            },
            showKeyboardToolbar: true,
            backgroundColor: .customWhite,
            textColor: .customInput,
            iconColor: .customInput,
            placeholderColor: .customPlaceholder
        )
    }
    
    //MARK: cellPatientStruct
    @ViewBuilder
    func cellPatientStruct(name: String, documment: String, age: String, gender: String) -> some View {
        VStack(alignment: .leading, spacing: 10){
            HStack(alignment: .top){
                VStack(alignment: .leading, spacing: 3){
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.customLabel)
                        .bold()
                    
                    Text("cpf: \(documment)")
                        .font(.caption)
                        .foregroundStyle(.customLabel)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
            }
            HStack {
                Text("Idade: \(age)")
                    .font(.caption)
                    .foregroundStyle(.customLabel)
                
                Spacer()
                
                Text("Sexo: \(gender)")
                    .font(.caption)
                    .foregroundStyle(.customLabel)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.customBackground)
        )
        .shadow(color: Color.customLabel.opacity(0.08), radius: 6, x: 0, y: 6)
//        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
}
