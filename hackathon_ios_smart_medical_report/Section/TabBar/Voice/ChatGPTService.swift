import Foundation

/// Serviço para comunicação com a API de Chat Completions da OpenAI (ChatGPT).
///
/// Como usar:
/// 1. Crie uma instância do `ChatGPTService` injetando sua API Key.
/// 2. Utilize as funções `send(prompt:)` ou `send(messages:)` para enviar mensagens ao modelo.
/// 3. Receba a resposta do assistente como `String`.
///
/// Exemplo básico com SwiftUI:
/// ```swift
/// @State private var response: String = ""
///
/// let service = ChatGPTService(apiKey: "sua_api_key_aqui")
///
/// Task {
///     do {
///         let reply = try await service.send(prompt: "Olá, quem é você?")
///         await MainActor.run {
///             response = reply
///         }
///     } catch {
///         print("Erro: \(error)")
///     }
/// }
/// ```
///
public struct ChatGPTService {

    private let apiKey: String
    private let baseURL: URL
    private let model: String

    /// Inicializa o serviço com a chave da API, URL base (opcional) e modelo (padrão "gpt-4o-mini").
    ///
    /// - Parameters:
    ///   - apiKey: Sua chave de API da OpenAI.
    ///   - baseURL: URL base da API de Chat Completions. Defaults para `https://api.openai.com/v1/chat/completions`.
    ///   - model: Modelo a ser usado na requisição. Padrão é "gpt-4o-mini".
    public init(apiKey: String, baseURL: URL? = nil, model: String = "gpt-4o-mini") {
        self.apiKey = apiKey
        self.baseURL = baseURL ?? URL(string: "https://api.openai.com/v1/chat/completions")!
        self.model = model
    }

    /// Envia um prompt simples ao modelo e recebe a resposta.
    ///
    /// - Parameters:
    ///   - prompt: Texto do usuário a ser enviado.
    ///   - systemPrompt: Prompt do sistema para orientar o modelo (opcional).
    ///   - temperature: Controla a aleatoriedade da resposta (padrão 0.7).
    ///   - maxTokens: Número máximo de tokens da resposta (opcional).
    ///   - timeout: Timeout da requisição em segundos (padrão 30).
    /// - Returns: Resposta do assistente como `String`.
    /// - Throws: `ChatGPTServiceError` em caso de falha.
    public func send(
        prompt: String,
        systemPrompt: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        timeout: TimeInterval = 30
    ) async throws -> String {
        var messages: [ChatMessage] = []
        if let system = systemPrompt {
            messages.append(ChatMessage(role: .system, content: system))
        }
        messages.append(ChatMessage(role: .user, content: prompt))
        return try await send(messages: messages, temperature: temperature, maxTokens: maxTokens, timeout: timeout)
    }

    /// Envia uma sequência de mensagens para o modelo, útil para conversas multi-turno.
    ///
    /// - Parameters:
    ///   - messages: Array de mensagens com papéis (system, user, assistant).
    ///   - temperature: Controla a aleatoriedade da resposta (padrão 0.7).
    ///   - maxTokens: Número máximo de tokens da resposta (opcional).
    ///   - timeout: Timeout da requisição em segundos (padrão 30).
    /// - Returns: Resposta do assistente como `String`.
    /// - Throws: `ChatGPTServiceError` em caso de falha.
    public func send(
        messages: [ChatMessage],
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        timeout: TimeInterval = 30
    ) async throws -> String {
        let requestBody = ChatCompletionsRequest(model: model, messages: messages, temperature: temperature, max_tokens: maxTokens)
        let request = try makeRequest(with: requestBody, timeout: timeout)
        let (data, response) = try await URLSession(configuration: .ephemeral).data(for: request)
        try validate(response: response, data: data)
        let decoded = try decodeResponse(data: data)
        guard let firstChoice = decoded.choices.first else {
            throw ChatGPTServiceError.emptyResponse
        }
        guard !firstChoice.message.content.isEmpty else {
            throw ChatGPTServiceError.emptyResponse
        }
        return firstChoice.message.content
    }

    // MARK: - Private helpers

    private func makeRequest(with body: ChatCompletionsRequest, timeout: TimeInterval) throws -> URLRequest {
        var request = URLRequest(url: baseURL, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatGPTServiceError.requestFailed(statusCode: -1, message: "Resposta não HTTP")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message: String?
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                message = errorResponse.error.message
            } else {
                message = String(data: data, encoding: .utf8)
            }
            throw ChatGPTServiceError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func decodeResponse(data: Data) throws -> ChatCompletionsResponse {
        do {
            return try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        } catch {
            throw ChatGPTServiceError.decodingFailed
        }
    }
}

/// Papel de uma mensagem no chat usada pela API do OpenAI.
public enum ChatRole: String, Codable, Sendable {
    case system
    case user
    case assistant
}

/// Representa uma mensagem enviada ou recebida do modelo.
public struct ChatMessage: Codable, Sendable {
    public let role: ChatRole
    public let content: String

    public init(role: ChatRole, content: String) {
        self.role = role
        self.content = content
    }
}

/// Estrutura da requisição para Chat Completions API da OpenAI.
struct ChatCompletionsRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
    let max_tokens: Int?

    init(model: String, messages: [ChatMessage], temperature: Double?, max_tokens: Int?) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.max_tokens = max_tokens
    }
}

/// Estrutura da resposta da API Chat Completions contendo a primeira escolha.
struct ChatCompletionsResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: ChatRole
            let content: String
        }
        let index: Int
        let message: Message
        let finish_reason: String?
    }

    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
}

/// Modelo para decodificar erros retornados pela API OpenAI.
struct OpenAIErrorResponse: Decodable {
    struct ErrorDetail: Decodable {
        let message: String
        let type: String?
        let param: String?
        let code: String?
    }
    let error: ErrorDetail
}

/// Erros que podem ocorrer no ChatGPTService.
public enum ChatGPTServiceError: Error, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int, message: String?)
    case emptyResponse
    case decodingFailed
    case timeout

    public static func == (lhs: ChatGPTServiceError, rhs: ChatGPTServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case let (.requestFailed(aCode, aMsg), .requestFailed(bCode, bMsg)):
            return aCode == bCode && aMsg == bMsg
        case (.emptyResponse, .emptyResponse): return true
        case (.decodingFailed, .decodingFailed): return true
        case (.timeout, .timeout): return true
        default: return false
        }
    }
}
