//
//  PatientDetailView.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import SwiftUI

struct PatientDetailView: View {
    //MARK: - PROPERTIES
    
    var patientId : String
    @State private var patient : Patient?
    @State private var report : [Report] = []
    
    private var filteredReports: [Report] {
        report.filter { r in
            // Try to access r.patient_id defensively via Mirror in case the property name differs
            if let pid = Mirror(reflecting: r).children.first(where: { $0.label == "patient_id" })?.value as? String {
                return pid == patientId
            }
            // Try common alternatives
            if let pid = Mirror(reflecting: r).children.first(where: { $0.label == "patientId" })?.value as? String {
                return pid == patientId
            }
            if let pid = Mirror(reflecting: r).children.first(where: { $0.label == "patientID" })?.value as? String {
                return pid == patientId
            }
            return false
        }
    }
    
    @State private var isLoading : Bool = false
    @State private var isReportLoading : Bool = false
    
    //Toast
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isErrorToast: Bool = false
    
    // MARK: - Helpers
    private var formattedBirthDate: String {
        // Adjust the key path to the actual birth date field on Patient if different
        // Expecting either a Date or a String ISO8601. Handle both defensively.
        guard let patient else { return "" }

        // Try Date field first if it exists via Mirror
        if let dateValue = Mirror(reflecting: patient).children.first(where: { $0.label == "birth_date" })?.value as? Date {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: dateValue)
        }

        // Try common string field names and parse
        let possibleKeys = ["birth_date", "birthDate", "date_of_birth", "dob"]
        for key in possibleKeys {
            if let stringValue = Mirror(reflecting: patient).children.first(where: { $0.label == key })?.value as? String {
                // Try ISO8601 first
                if let isoDate = ISO8601DateFormatter().date(from: stringValue) {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "pt_BR")
                    formatter.dateFormat = "dd/MM/yyyy"
                    return formatter.string(from: isoDate)
                }
                // Try a few common server formats
                let fmts = [
                    "yyyy-MM-dd",
                    "yyyy/MM/dd",
                    "dd-MM-yyyy",
                    "dd/MM/yyyy"
                ]
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                for f in fmts {
                    df.dateFormat = f
                    if let d = df.date(from: stringValue) {
                        let out = DateFormatter()
                        out.locale = Locale(identifier: "pt_BR")
                        out.dateFormat = "dd/MM/yyyy"
                        return out.string(from: d)
                    }
                }
                // If already in desired format, return as-is
                if stringValue.count == 10 && stringValue.contains("/") { return stringValue }
            }
        }
        return ""
    }

    private var localizedGender: String {
        guard let patient else { return "" }
        // Try to read a gender-like property defensively
        let possibleGenderKeys = ["gender", "sex", "genero"]
        var raw: String = ""
        for key in possibleGenderKeys {
            if let value = Mirror(reflecting: patient).children.first(where: { $0.label == key })?.value as? String {
                raw = value
                break
            }
        }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "male", "masculino", "m":
            return "Masculino"
        case "female", "feminino", "f":
            return "Feminino"
        default:
            return raw.isEmpty ? "" : raw
        }
    }
    
    //MARK: - FUNCTIONS
    
    func getByPatientId(){
        isLoading = true
        UserAPI.patientById(patientId: patientId) { response in
            isLoading = false
            if response.success {
                patient = response.patient
            } else {
                isErrorToast = true
                Helper.showToast(isPresented: $showToast, text: $toastMessage, response.erroMessage, isError: isErrorToast)
            }
        }
    }
    
    func listReports() {
        isReportLoading = true
        UserAPI.listReports { response in
            isReportLoading = false
            if response.success {
                // Assign all reports first; UI will read filteredReports
                self.report = response.reports ?? []
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
                Color.customBackground.ignoresSafeArea()
                mainStrucr()
            }
            .toast(isPresented: $showToast, text: $toastMessage, isError: isErrorToast)
            .redacted(reason: isLoading ? .placeholder : [])
            .onAppear {
                getByPatientId()
                listReports()
            }
        }
    }
    
    //MARK: mainStrucr
    @ViewBuilder
    func mainStrucr() -> some View {
        VStack(alignment: .leading, spacing: 15){
            topStruct()
            
            Text("Laudos")
                .foregroundStyle(.customLabel)
                .font(.title3)
                .fontWeight(.semibold)
            
            ScrollView(.vertical, showsIndicators: false) {
                if isReportLoading {
                    VStack(spacing: 16) {
                        ForEach(0 ..< 3, id: \.self) { _ in
                            cellPatientStruct(name: "—", date: "—", result: "—", conclusions: "—", observations: "—", isPending: false)
                                .redacted(reason: .placeholder)
                        }
                    }
                } else if filteredReports.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.customLabel.opacity(0.6))
                        Text("Paciente sem nenhum laudo")
                            .foregroundStyle(.customLabel.opacity(0.8))
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    VStack(spacing: 16) {
                        ForEach(Array(filteredReports.enumerated()), id: \.offset) { _, r in
                            // Safely extract fields using Mirror to avoid compile issues if names differ
                            let dateStr: String = {
                                if let d = Mirror(reflecting: r).children.first(where: { $0.label == "date" })?.value as? Date {
                                    let f = DateFormatter()
                                    f.locale = Locale(identifier: "pt_BR")
                                    f.dateFormat = "dd/MM/yyyy"
                                    return f.string(from: d)
                                }
                                if let s = Mirror(reflecting: r).children.first(where: { $0.label == "date" || $0.label == "created_at" || $0.label == "createdAt" })?.value as? String {
                                    // Try ISO8601 with fractional seconds and timezone (e.g., 2025-10-25T17:21:18.227619+00:00)
                                    let iso = ISO8601DateFormatter()
                                    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                    if let d1 = iso.date(from: s) {
                                        let f = DateFormatter()
                                        f.locale = Locale(identifier: "pt_BR")
                                        f.dateFormat = "dd/MM/yyyy"
                                        return f.string(from: d1)
                                    }
                                    // Fallback: standard ISO8601 without fractional seconds
                                    let isoNoFrac = ISO8601DateFormatter()
                                    isoNoFrac.formatOptions = [.withInternetDateTime]
                                    if let d2 = isoNoFrac.date(from: s) {
                                        let f = DateFormatter()
                                        f.locale = Locale(identifier: "pt_BR")
                                        f.dateFormat = "dd/MM/yyyy"
                                        return f.string(from: d2)
                                    }
                                    // Try a few manual formats if server varies
                                    let fmts = [
                                        "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                                        "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                                        "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
                                        "yyyy-MM-dd"
                                    ]
                                    let df = DateFormatter()
                                    df.locale = Locale(identifier: "en_US_POSIX")
                                    for fmt in fmts {
                                        df.dateFormat = fmt
                                        if let d = df.date(from: s) {
                                            let out = DateFormatter()
                                            out.locale = Locale(identifier: "pt_BR")
                                            out.dateFormat = "dd/MM/yyyy"
                                            return out.string(from: d)
                                        }
                                    }
                                    // If nothing parsed, return original string
                                    return s
                                }
                                return ""
                            }()
                            let result = (Mirror(reflecting: r).children.first { $0.label == "result" }?.value as? String) ?? ""
                            let conclusions = (Mirror(reflecting: r).children.first { $0.label == "conclusions" }?.value as? String) ?? ""
                            let observations = (Mirror(reflecting: r).children.first { $0.label == "observations" }?.value as? String) ?? ""
                            
                            let isPending = (r.status == "draft")
                            let reportId: String = {
                                if let v = Mirror(reflecting: r).children.first(where: { $0.label == "id" })?.value as? String { return v }
                                if let v = Mirror(reflecting: r).children.first(where: { $0.label == "_id" })?.value as? String { return v }
                                if let v = Mirror(reflecting: r).children.first(where: { $0.label == "report_id" })?.value as? String { return v }
                                if let v = Mirror(reflecting: r).children.first(where: { $0.label == "reportId" })?.value as? String { return v }
                                return ""
                            }()

                            Group {
                                if isPending, !reportId.isEmpty {
                                    NavigationLink {
                                        VoiceGptView(reportId: r.id, reportType: r.exam_type)
                                    } label: {
                                        cellPatientStruct(name: r.exam_type, date: dateStr, result: result, conclusions: conclusions, observations: observations, isPending: true)
                                    }
                                } else {
                                    cellPatientStruct(name: r.exam_type, date: dateStr, result: result, conclusions: conclusions, observations: observations, isPending: false)
                                        .contextMenu(forSelectionType: <#T##Hashable.Type#>, menu: <#T##(Set<Hashable>) -> View#>)
                                }
                            }
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
        VStack(alignment: .leading){
            Text(patient?.full_name ?? "")
                .font(.title2)
                .foregroundStyle(.customLabel)
                .bold()
            
            detailPatientStruct(title: "CPF", value: patient?.tax_id.formatMask(maskStr: "XXX.XXX.XXX-XX") ?? "")
            
            detailPatientStruct(title: "Nascimento", value: formattedBirthDate)
            
            detailPatientStruct(title: "Gênero", value: localizedGender)
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.customBackground)
        )
        .shadow(color: Color.customLabel.opacity(0.08), radius: 6, x: 0, y: 6)
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
                
            }
            VStack(alignment: .leading){
                Text("CONCLUSÕES")
                    .font(.subheadline)
                    .foregroundStyle(.customLabel)
                    .fontWeight(.medium)
                Text("\(conclusions)")
                    .font(.caption)
                    .foregroundStyle(.customLabel)
            }
            
            VStack(alignment: .leading){
                Text("OBSERVAÇÕES")
                    .font(.subheadline)
                    .foregroundStyle(.customLabel)
                    .fontWeight(.medium)
                Text("\(observations)")
                    .font(.caption)
                    .foregroundStyle(.customLabel)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.customBackground)
        )
        .shadow(color: Color.customLabel.opacity(0.08), radius: 6, x: 0, y: 6)
//        .padding(.vertical, 4)
    }
    
    //MARK: detailPatientStruct
    @ViewBuilder
    func detailPatientStruct(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.customLabel)
                .bold()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.customLabel)
                Spacer()
        }
    }
}

#Preview {
    PatientDetailView(patientId: "wkjrncvkjrnckjn")
}

