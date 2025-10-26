//
//  VoiceView.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import SwiftUI

struct VoiceView: View {
    //MARK: - PROPERTIES
    
    @State private var searchTF : String = ""
    @State private var report : [Report] = []
    @State private var patients : [Patient] = []
    @State private var patientsByID: [String: Patient] = [:]
    
    @State private var isLoading : Bool = false
    
    // Date formatters
    private static let apiDateParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let dayMonthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    private func formatAPIDate(_ value: Any?) -> String {
        // Accept String or Date; fallback to dash
        if let s = value as? String, let date = VoiceView.apiDateParser.date(from: s) {
            return VoiceView.dayMonthYearFormatter.string(from: date)
        } else if let d = value as? Date {
            return VoiceView.dayMonthYearFormatter.string(from: d)
        } else {
            return "—"
        }
    }
    
    private let placeholderPatients: [Report] = Array(repeating: Report(), count: 3)
    
    //Toast
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isErrorToast: Bool = false
    
    //MARK: - FUNCTIONS
    
    func listReports() {
        isLoading = true
        UserAPI.listReports { response in
            isLoading = false
            if response.success {
                // Assign all reports first; UI will read filteredReports
                self.report = response.reports ?? []
            } else {
                isErrorToast = true
                Helper.showToast(isPresented: $showToast, text: $toastMessage, response.erroMessage, isError: isErrorToast)
            }
        }
    }
    
    func listPatient() {
        isLoading = true
        
        UserAPI.listPatient { response in
            isLoading = false
            if response.success {
                patients = response.patients
                patientsByID = Dictionary(uniqueKeysWithValues: patients.map { (String($0.id), $0) })
            } else {
                isErrorToast = true
                Helper.showToast(isPresented: $showToast, text: $toastMessage, response.erroMessage, isError: isErrorToast)
            }
        }
    }
    
    // Filtered reports: only drafts, and by search text if provided
    var filteredReports: [Report] {
        // Keep only drafts
        let drafts = report.filter { ($0.status as? String)?.lowercased() == "draft" || ($0.status as? String) == nil && (String(describing: $0.status).lowercased() == "draft") }
        let query = searchTF.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return drafts }
        return drafts.filter { r in
            let pid: String = {
                if let s = r.patient_id as? String { return s }
                return String(describing: r.patient_id)
            }()
            let name = patientsByID[pid]?.full_name ?? ""
            return name.localizedCaseInsensitiveContains(query) || pid.localizedCaseInsensitiveContains(query)
        }
    }
    
    //MARK: - BODY
    var body: some View {
        ZStack {
            Color.customBackground.ignoresSafeArea()
            mainStrucr()
        }
        .toast(isPresented: $showToast, text: $toastMessage, isError: isErrorToast)
    }
    //MARK: mainStrucr
    @ViewBuilder
    func mainStrucr() -> some View {
        VStack(alignment: .leading){
            topStruct()
            
            ScrollView(.vertical, showsIndicators: false){
                VStack(spacing: 16){
                    if filteredReports.isEmpty && !isLoading {
                        Text("Nenhum laudo pendente")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    }
                    ForEach(Array(isLoading ? placeholderPatients.enumerated() : filteredReports.enumerated()), id: \.offset) { _, item in
                        let pid: String = {
                            if let s = item.patient_id as? String { return s }
                            return String(describing: item.patient_id)
                        }()
                        let patientName = patientsByID[pid]?.full_name ?? pid
                        let dateText: String = formatAPIDate(item.created_at)
                        NavigationLink {
                            VoiceGptView(reportId: item.id, reportType: item.exam_type)
                        } label: {
                            cellPatientStruct(
                                name: patientName.isEmpty ? "—" : patientName,
                                date: dateText.isEmpty ? "—" : dateText,
                                result: (item.results as? String) ?? String(describing: item.results),
                                conclusions: (item.conclusions as? String) ?? String(describing: item.conclusions),
                                observations: (item.observations as? String) ?? String(describing: item.observations),
                                isPending: ((item.status as? String)?.lowercased() == "draft")
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            if report.isEmpty { listReports() }
            if patients.isEmpty { listPatient() }
        }
    }
    
    //MARK: topStruct
    @ViewBuilder
    func topStruct() -> some View {
        Text("Listagem de Laudos")
            .font(.title3)
            .foregroundStyle(.customLabel)
        
        Text("Pendentes")
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
    func cellPatientStruct(name: String, date: String, result: String, conclusions: String, observations: String, isPending: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10){
            HStack(alignment: .top){
                VStack(alignment: .leading, spacing: 3){
                    Text(name)
                        .font(.title3)
                        .foregroundStyle(.customLabel)
                        .bold()
                    
                    Text("\(date)")
                        .font(.caption)
                        .foregroundStyle(.customLabel)
                }
                
                Spacer()
                
                if isPending {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                }
            }
            VStack(alignment: .leading){
                Text("RESULTADOS")
                    .font(.subheadline)
                    .foregroundStyle(.customLabel)
                    .fontWeight(.medium)
                
                Text("\(result)")
                    .font(.caption)
                    .foregroundStyle(.customLabel)
                    .multilineTextAlignment(.leading)
                
            }
            VStack(alignment: .leading){
                Text("CONCLUSÕES")
                    .font(.subheadline)
                    .foregroundStyle(.customLabel)
                    .fontWeight(.medium)
                Text("\(conclusions)")
                    .font(.caption)
                    .foregroundStyle(.customLabel)
                    .multilineTextAlignment(.leading)
            }
            
            VStack(alignment: .leading){
                Text("OBSERVAÇÕES")
                    .font(.subheadline)
                    .foregroundStyle(.customLabel)
                    .fontWeight(.medium)
                Text("\(observations)")
                    .font(.caption)
                    .foregroundStyle(.customLabel)
                    .multilineTextAlignment(.leading)
            }
            
            HStack {
                Circle()
                    .frame(width: 8)
                
                Text(isPending ? "Pendente" : "Concluído")
                    .font(.caption2)
            }
            .foregroundStyle(isPending ? .customRed : .customGreen)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isPending ? .customRed.opacity(0.2) : .customGreen.opacity(0.2))
            )
        }
        .redacted(reason: isLoading ? .placeholder : [])
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
    VoiceView()
}

