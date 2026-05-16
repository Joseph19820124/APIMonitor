import Foundation

struct CodexService: ProviderService {
    private let base = "https://api.openai.com/v1"

    func fetchUsage(apiKey: String) async throws -> UsageData {
        let token = try loadCodexAccessToken()
        let cal = Calendar.current
        let now = Date()
        let todayStart = cal.startOfDay(for: now)
        let thirtyAgo = cal.date(byAdding: .day, value: -30, to: todayStart)!
        let sevenAgo = cal.date(byAdding: .day, value: -7, to: todayStart)!
        let start = Int(thirtyAgo.timeIntervalSince1970)
        let end = Int(now.timeIntervalSince1970)
        let headers = ["Authorization": "Bearer \(token)"]

        let costsURL = try makeURL(
            path: "/organization/costs",
            query: [
                "start_time": "\(start)",
                "end_time": "\(end)",
                "bucket_width": "1d"
            ]
        )
        let costs: OpenAICostsResponse = try await fetchOpenAIJSON(
            costsURL,
            headers: headers
        )

        let usageURL = try makeURL(
            path: "/organization/usage/completions",
            query: [
                "start_time": "\(start)",
                "end_time": "\(end)",
                "bucket_width": "1d",
                "group_by": "model",
                "limit": "31"
            ]
        )
        let usage: OpenAIUsageResponse = try await fetchOpenAIJSON(
            usageURL,
            headers: headers
        )

        let dailySpend = costs.data.compactMap { bucket -> UsageData.DailyPoint? in
            let spend = bucket.results.reduce(0) { $0 + ($1.amount?.value ?? 0) }
            return UsageData.DailyPoint(
                date: Date(timeIntervalSince1970: TimeInterval(bucket.startTime)),
                spend: spend
            )
        }.sorted { $0.date < $1.date }

        let todaySpend = dailySpend
            .filter { cal.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.spend }
        let sevenDaySpend = dailySpend
            .filter { $0.date >= sevenAgo }
            .reduce(0) { $0 + $1.spend }
        let thirtyDaySpend = dailySpend.reduce(0) { $0 + $1.spend }

        var todayRequests = 0
        var thirtyDayTokens = 0
        var thirtyDayRequests = 0
        var tokensByModel: [String: Int] = [:]

        for bucket in usage.data {
            let date = Date(timeIntervalSince1970: TimeInterval(bucket.startTime))
            for result in bucket.results {
                let tokens = result.inputTokens + result.outputTokens
                let requests = result.numModelRequests
                thirtyDayTokens += tokens
                thirtyDayRequests += requests
                if cal.isDateInToday(date) {
                    todayRequests += requests
                }
                if let model = result.model, !model.isEmpty {
                    tokensByModel[model, default: 0] += tokens
                }
            }
        }

        let topModel = tokensByModel.max(by: { $0.value < $1.value })?.key ?? "Codex"

        return UsageData(
            todaySpend: todaySpend,
            sevenDaySpend: sevenDaySpend,
            thirtyDaySpend: thirtyDaySpend,
            todayRequests: todayRequests,
            thirtyDayTokens: thirtyDayTokens,
            thirtyDayRequests: thirtyDayRequests,
            topModel: topModel,
            dailySpend: dailySpend
        )
    }

    private func makeURL(path: String, query: [String: String]) throws -> URL {
        var components = URLComponents(string: base + path)
        components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components?.url else { throw APIError.decodingError }
        return url
    }

    private func fetchOpenAIJSON<T: Decodable>(_ url: URL, headers: [String: String]) async throws -> T {
        var req = URLRequest(url: url)
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.decodingError }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw APIError.serviceMessage(
                    "Codex OAuth is present, but OpenAI Usage API rejected it. Run codex login again; if this persists, this OAuth account may not expose organization usage details."
                )
            }
            throw APIError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func loadCodexAccessToken() throws -> String {
        let authURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/auth.json")
        guard let data = try? Data(contentsOf: authURL),
              let auth = try? JSONDecoder().decode(CodexAuth.self, from: data),
              let token = auth.tokens?.accessToken,
              !token.isEmpty
        else {
            throw APIError.notLoggedIn("Codex OAuth not found. Run codex login once, then refresh.")
        }
        return token
    }
}

private struct CodexAuth: Decodable {
    let tokens: Tokens?

    struct Tokens: Decodable {
        let accessToken: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }
}

private struct OpenAICostsResponse: Decodable {
    let data: [Bucket]

    struct Bucket: Decodable {
        let startTime: Int
        let results: [Result]

        enum CodingKeys: String, CodingKey {
            case startTime = "start_time"
            case results
        }
    }

    struct Result: Decodable {
        let amount: Amount?
    }

    struct Amount: Decodable {
        let value: Double
        let currency: String?
    }
}

private struct OpenAIUsageResponse: Decodable {
    let data: [Bucket]

    struct Bucket: Decodable {
        let startTime: Int
        let results: [Result]

        enum CodingKeys: String, CodingKey {
            case startTime = "start_time"
            case results
        }
    }

    struct Result: Decodable {
        let model: String?
        let inputTokens: Int
        let outputTokens: Int
        let numModelRequests: Int

        enum CodingKeys: String, CodingKey {
            case model
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case numModelRequests = "num_model_requests"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            model = try c.decodeIfPresent(String.self, forKey: .model)
            inputTokens = try c.decodeIfPresent(Int.self, forKey: .inputTokens) ?? 0
            outputTokens = try c.decodeIfPresent(Int.self, forKey: .outputTokens) ?? 0
            numModelRequests = try c.decodeIfPresent(Int.self, forKey: .numModelRequests) ?? 0
        }
    }
}
