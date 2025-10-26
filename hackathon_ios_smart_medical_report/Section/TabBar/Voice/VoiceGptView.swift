//
//  VoiceGptView.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import SwiftUI
import Speech
import AVFoundation
import UIKit

struct VoiceGptView: View {
    //MARK: - PROPERTIES
    var reportId: String
    var reportType: String
    
    // Chave fixa (ideal mover para armazenamento seguro / secrets em produção)
    @State private var apiKey: String = ""
    
    // Reconhecimento de voz
    @State private var speechAuthStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @State private var isRecording: Bool = false
    @State private var transcript: String = ""
    
    // Chat
    @State private var responseText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var observations: String = ""
    @State private var conclusions: String = ""
    @State private var resultsSection: String = ""
    
    // Exibição animada da resposta
    @State private var displayedResponse: String = ""
    @State private var loadingDots: Int = 0
    @State private var showPostReplyActions: Bool = false
    
    // Animated section text
    @State private var animatedConclusions: String = ""
    @State private var animatedObservations: String = ""
    @State private var animatedResults: String = ""
    
    // Áudio e reconhecimento
    @State private var audioEngine: AVAudioEngine? = nil
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? = nil
    @State private var recognitionTask: SFSpeechRecognitionTask? = nil
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages.first ?? "pt-BR"))
        
    //Toast
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isErrorToast: Bool = false
    
    @State private var isSharePresented: Bool = false
    @State private var sharedFileURL: URL? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - PDF Sharing
    private func shareSamplePDF() {
        let urlString = "https://www.thecampusqdl.com/uploads/files/pdf_sample_2.pdf"
        downloadPDF(toFilename: "arquivo.pdf", from: urlString) { result in
            switch result {
            case .success(let fileURL):
                DispatchQueue.main.async {
                    self.sharedFileURL = fileURL
                    self.isSharePresented = true
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isErrorToast = true
                    Helper.showToast(isPresented: $showToast, text: $toastMessage, "Falha ao preparar PDF: \(error.localizedDescription)", isError: isErrorToast)
                }
            }
        }
    }
    
    private func downloadPDF(toFilename filename: String, from urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "VoiceGptView", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])));
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let data = data, !data.isEmpty else {
                completion(.failure(NSError(domain: "VoiceGptView", code: -2, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida do servidor"])));
                return
            }
            do {
                let docs = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileURL = docs.appendingPathComponent(filename)
                try data.write(to: fileURL, options: .atomic)
                completion(.success(fileURL))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    //MARK: - FUNCTIONS
    
    func updateReport() {
        isLoading = true
        
        let params: [String: Any] = [
            "status" : "draft",
            "conclusions" : conclusions,
            "observations" : observations,
            "results" : resultsSection
        ]
        
        UserAPI.updateReport(reportId: reportId, params: params) { response in
            isLoading = false
            if response.success {
                isErrorToast = false
                Helper.showToast(isPresented: $showToast, text: $toastMessage, "Campos atualizados com sucesso!", isError: isErrorToast)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                    dismiss()
                }
            } else {
                isErrorToast = true
                Helper.showToast(isPresented: $showToast, text: $toastMessage, response.erroMessage, isError: isErrorToast)
            }
        }
    }
    
    // MARK: - Envio para API
    private func sendTranscript() {
        guard !isLoading else { return }
        errorMessage = nil
        let userPrompt = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !userPrompt.isEmpty else { return }
        
        conclusions = ""; observations = ""; resultsSection = ""
        animatedConclusions = ""; animatedObservations = ""; animatedResults = ""
        showPostReplyActions = false
        
        isLoading = true
        displayedResponse = ""
        Task {
            do {
                let service = ChatGPTService(apiKey: apiKey)
                let fullPrompt = "crie um laudo de \(reportType), \(userPrompt), avalie as possiblidades. Se possível, separe o texto em seções nomeadas: Conclusões, Observações e Resultados. Preciso de um codigo sem campo para preencher como nome do medico, crm, instituição entre outras, quero apenas o resultado do laudo e sem carcteres como *, **, :** e sem campos como []"
                let reply = try await service.send(prompt: fullPrompt)
                responseText = reply
                
                // Tenta decodificar JSON com chaves esperadas
                struct ReportResponse: Decodable { let observacoes: String?; let conclusoes: String?; let resultados: String? }
                var filledAny = false
                if let data = reply.data(using: .utf8), let decoded = try? JSONDecoder().decode(ReportResponse.self, from: data) {
                    if let c = decoded.conclusoes, !c.isEmpty { conclusions = c; filledAny = true }
                    if let o = decoded.observacoes, !o.isEmpty { observations = o; filledAny = true }
                    if let r = decoded.resultados, !r.isEmpty { resultsSection = r; filledAny = true }
                }
                // Heurística por marcadores em texto livre (case-insensitive)
                if !filledAny {
                    let text = reply
                    let lower = text.lowercased()
                    func range(of marker: String, from: String.Index? = nil) -> Range<String.Index>? {
                        let start = from ?? lower.startIndex
                        return lower.range(of: marker, range: start..<lower.endIndex)
                    }
                    func extract(after marker: String, until nextMarkers: [String], startFrom: inout String.Index) -> String? {
                        guard let r = range(of: marker, from: startFrom) else { return nil }
                        let start = text.index(text.startIndex, offsetBy: r.upperBound.utf16Offset(in: lower))
                        var end = text.endIndex
                        for m in nextMarkers {
                            if let nr = lower.range(of: m, range: r.upperBound..<lower.endIndex) {
                                let candidateEnd = text.index(text.startIndex, offsetBy: nr.lowerBound.utf16Offset(in: lower))
                                if candidateEnd < end { end = candidateEnd }
                            }
                        }
                        startFrom = end
                        let s = text[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
                        return s.isEmpty ? nil : String(s)
                    }
                    var cursor = lower.startIndex
                    let markers = ["conclusões", "conclusao", "conclusao:", "conclusões:", "conclusões -", "conclusao -",
                                   "observações", "observacao", "observações:", "observacao:",
                                   "resultados", "resultado", "resultados:", "resultado:"]
                    if let c = extract(after: "conclusões", until: ["observações", "observacao", "resultados", "resultado"], startFrom: &cursor) ??
                              extract(after: "conclusao", until: ["observações", "observacao", "resultados", "resultado"], startFrom: &cursor) {
                        conclusions = c; filledAny = true
                    }
                    cursor = lower.startIndex
                    if let o = extract(after: "observações", until: ["conclusões", "conclusao", "resultados", "resultado"], startFrom: &cursor) ??
                              extract(after: "observacao", until: ["conclusões", "conclusao", "resultados", "resultado"], startFrom: &cursor) {
                        observations = o; filledAny = true
                    }
                    cursor = lower.startIndex
                    if let r = extract(after: "resultados", until: ["conclusões", "conclusao", "observações", "observacao"], startFrom: &cursor) ??
                              extract(after: "resultado", until: ["conclusões", "conclusao", "observações", "observacao"], startFrom: &cursor) {
                        resultsSection = r; filledAny = true
                    }
                }
            } catch {
                if let e = error as? ChatGPTServiceError {
                    switch e {
                    case .invalidURL:
                        errorMessage = "URL inválida."
                    case .requestFailed(let status, let message):
                        errorMessage = "Falha na requisição (status: \(status)). \(message)"
                        print("Falha na requisição (status: \(status)).\(message)")
                    case .emptyResponse:
                        errorMessage = "Resposta vazia do servidor."
                    case .decodingFailed:
                        errorMessage = "Falha ao interpretar a resposta."
                    case .timeout:
                        errorMessage = "Tempo de requisição esgotado."
                    }
                } else {
                    errorMessage = error.localizedDescription
                    print(error.localizedDescription)
                }
            }
            isLoading = false
            
            if conclusions.isEmpty && observations.isEmpty && resultsSection.isEmpty {
                // No structured sections detected: animate the raw response
                typeOut(responseText, into: $displayedResponse)
            } else {
                // Animate each non-empty section
                if !conclusions.isEmpty { typeOut(conclusions, into: $animatedConclusions) }
                if !observations.isEmpty { typeOut(observations, into: $animatedObservations) }
                if !resultsSection.isEmpty { typeOut(resultsSection, into: $animatedResults) }
                displayedResponse = "" // ensure plain area is empty when sections are present
            }
            showPostReplyActions = true
        }
    }
    
    private func speakAgain() {
        // Clear UI but preserve previous transcript logically by just resetting the visible value
        displayedResponse = ""
        animatedConclusions = ""; animatedObservations = ""; animatedResults = ""
        conclusions = ""; observations = ""; resultsSection = ""
        transcript = "" // reset the visible transcript
        showPostReplyActions = false
        startRecording()
    }
    
    // MARK: - Speech
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { self.speechAuthStatus = status }
        }
    }
    
    private func toggleRecording() {
        if isRecording { stopRecording(autoSend: true) } else { startRecording() }
    }
    
    private func startRecording() {
        guard speechAuthStatus == .authorized else {
            errorMessage = "Permissão de fala não concedida."
            return
        }
        
        displayedResponse = ""
        animatedConclusions = ""; animatedObservations = ""; animatedResults = ""
        errorMessage = nil
        
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            self.errorMessage = "Não foi possível iniciar a gravação: \(error.localizedDescription)"
            return
        }
        
        self.audioEngine = audioEngine
        self.recognitionRequest = request
        self.isRecording = true
        showPostReplyActions = false
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async { self.transcript = text }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.stopRecording(autoSend: false)
                }
            }
            
            if let result = result, result.isFinal {
                DispatchQueue.main.async { self.stopRecording(autoSend: true) }
            }
        }
    }
    
    private func stopRecording(autoSend: Bool) {
        isRecording = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        if autoSend { sendTranscript() }
    }
    
    private func typeOut(_ full: String, into binding: Binding<String>, charDelay: UInt64 = 20_000_000) {
        binding.wrappedValue = ""
        Task { @MainActor in
            var index = full.startIndex
            while index < full.endIndex {
                let nextIndex = full.index(after: index)
                binding.wrappedValue.append(contentsOf: full[index..<nextIndex])
                try? await Task.sleep(nanoseconds: charDelay)
                index = nextIndex
            }
        }
    }
}

// MARK: - Floating Mic Button
private struct FloatingMicButton: View {
    var isRecording: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: isRecording ? [.red, .pink] : [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 68, height: 68)
                    .shadow(color: (isRecording ? Color.red : Color.purple).opacity(0.4), radius: 12, x: 0, y: 6)
                
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel(isRecording ? "Parar gravação" : "Iniciar gravação")
        .buttonStyle(.plain)
        .overlay(
            PulsatingRing(isActive: isRecording)
        )
    }
}

// Anel pulsante em torno do botão de microfone
private struct PulsatingRing: View {
    var isActive: Bool
    @State private var pulse = false
    
    var body: some View {
        Circle()
            .strokeBorder(
                AngularGradient(gradient: Gradient(colors: [.purple, .blue, .cyan, .purple]), center: .center)
                , lineWidth: 2
            )
            .frame(width: 86, height: 86)
            .scaleEffect(isActive ? (pulse ? 1.15 : 0.95) : 1.0)
            .opacity(isActive ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.9).repeatForever().speed(1.0), value: pulse)
            .onAppear { pulse = true }
    }
}

// Erros locais para validação simples
private enum LocalError: Error { case missingAPIKey }

#Preview {
    VoiceGptView(reportId: "", reportType: "")
}

extension VoiceGptView {
    var body: some View {
        ZStack {
            // Fundo com gradiente animado sutil (tema IA)
            Color.customBackground.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Cabeçalho simples
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Assistente de Voz")
                            .font(.largeTitle).bold()
                        Text("Descreva os detalhes para gerar o laudo")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(transcript == "" ? "Aguardando detalhes..." : transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Área de resposta
                    Group {
                        Group {
                            if isLoading {
                                Text("Gerando laudo" + String(repeating: ".", count: loadingDots))
                                    .italic()
                                    .foregroundStyle(.secondary)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {}
                                    }
                            } else if !observations.isEmpty || !conclusions.isEmpty || !resultsSection.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    if !conclusions.isEmpty {
                                        Text("Conclusões").font(.headline)
                                        Text(animatedConclusions.isEmpty ? conclusions : animatedConclusions)
                                    }
                                    if !observations.isEmpty {
                                        Text("Observações").font(.headline)
                                        Text(animatedObservations.isEmpty ? observations : animatedObservations)
                                    }
                                    if !resultsSection.isEmpty {
                                        Text("Resultados").font(.headline)
                                        Text(animatedResults.isEmpty ? resultsSection : animatedResults)
                                    }
                                }
                            } else if displayedResponse.isEmpty {
                                Text("A resposta aparecerá aqui.")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(displayedResponse)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack{
                        if showPostReplyActions && !isLoading {
                            HStack(spacing: 12) {
                                Button {
                                    speakAgain()
                                } label: {
                                    Text("Falar novamente")
                                        .frame(height: 35)
                                        .frame(maxWidth: .infinity)
                                        .background(.thinMaterial, in: Capsule())
                                }
                                
                                Button {
                                    updateReport()
                                } label: {
                                    Text("Atualizar campos")
                                        .frame(height: 35)
                                        .frame(maxWidth: .infinity)
                                        .background(.thinMaterial, in: Capsule())
                                }
                                
                                Button {
                                    shareSamplePDF()
                                } label: {
                                    Text("Compartilhar PDF")
                                        .frame(height: 35)
                                        .frame(maxWidth: .infinity)
                                        .background(.thinMaterial, in: Capsule())
                                }
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 28)
                        }
                    }
                }
                .padding()
            }
            // Botão flutuante de microfone ou ações pós-resposta
            VStack {
                Spacer()
                HStack {
                    Spacer()
                     if !showPostReplyActions{
                        FloatingMicButton(isRecording: isRecording) {
                            toggleRecording()
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .toast(isPresented: $showToast, text: $toastMessage, isError: isErrorToast)
        .onAppear {
            requestSpeechAuthorization()
            // Timer para animar os pontos do placeholder enquanto isLoading for true
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                if isLoading {
                    loadingDots = (loadingDots + 1) % 4
                } else if loadingDots != 0 {
                    loadingDots = 0
                }
            }
        }
        .sheet(isPresented: $isSharePresented) {
            if let fileURL = sharedFileURL {
                ActivityView(activityItems: [fileURL])
                    .presentationDetents([.medium, .large])
            } else {
                Text("Nada para compartilhar")
                    .padding()
            }
        }
    }
}

// Wrapper para UIActivityViewController
struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
