import Foundation

protocol ProviderService {
    func fetchUsage(apiKey: String) async throws -> UsageData
}

enum APIError: LocalizedError {
    case noAPIKey
    case httpError(Int)
    case decodingError
    case notSupported

    var errorDescription: String? {
        switch self {
        case .noAPIKey:          return "API Key not configured"
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
        guard (200..<300).contains(http.statusCode) else { throw APIError.httpError(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
