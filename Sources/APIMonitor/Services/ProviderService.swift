import Foundation

protocol ProviderService {
    func fetchUsage(apiKey: String) async throws -> UsageData
}

enum APIError: LocalizedError {
    case noAPIKey
    case notLoggedIn(String)
    case serviceMessage(String)
    case httpError(Int)
    case decodingError
    case notSupported

    var errorDescription: String? {
        switch self {
        case .noAPIKey:          return "API Key not configured"
        case .notLoggedIn(let s): return s
        case .serviceMessage(let s): return s
        case .httpError(let c):  return "HTTP \(c)"
        case .decodingError:     return "Invalid response"
        case .notSupported:      return "Usage API not supported"
        }
    }
}

extension URLSession {
    func fetchJSON<T: Decodable>(_ url: URL, headers: [String: String]) async throws -> T {
        var req = URLRequest(url: url)
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, resp) = try await data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.decodingError }
        guard (200..<300).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
                throw APIError.serviceMessage(apiError.displayMessage(statusCode: http.statusCode))
            }
            throw APIError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct ServiceErrorResponse: Decodable {
    let error: ServiceError?
    let msg: String?
    let message: String?

    func displayMessage(statusCode: Int) -> String {
        let detail = error?.message ?? message ?? msg
        guard let detail, !detail.isEmpty else {
            return "HTTP \(statusCode)"
        }
        return "HTTP \(statusCode): \(detail)"
    }

    struct ServiceError: Decodable {
        let code: String?
        let message: String?
    }
}
