import Foundation

struct AnthropicService: ProviderService {
    private let base = "https://api.anthropic.com/v1"
    private let version = "2023-06-01"

    func fetchUsage(apiKey: String) async throws -> UsageData {
        let cal = Calendar.current
        let now = Date()
        let todayStart = cal.startOfDay(for: now)
        let thirtyAgo = cal.date(byAdding: .day, value: -30, to: todayStart)!
        let sevenAgo  = cal.date(byAdding: .day, value: -7,  to: todayStart)!

        let fmt = ISO8601DateFormatter()

        // 30天费用（按天分组）
        let costURL = URL(string: "\(base)/organizations/cost_report?starting_at=\(fmt.string(from: thirtyAgo))&ending_at=\(fmt.string(from: now))&bucket_width=1d")!
        let costResp: AnthropicCostResponse = try await URLSession.shared.fetchJSON(
            costURL, headers: headers(apiKey: apiKey))

        let dailyPoints = costResp.data.compactMap { item -> UsageData.DailyPoint? in
            guard let date = fmt.date(from: item.start_time),
                  let cost = Double(item.cost_usd) else { return nil }
            return UsageData.DailyPoint(date: date, spend: cost / 100.0)
        }.sorted { $0.date < $1.date }

        let total30  = dailyPoints.reduce(0) { $0 + $1.spend }
        let total7   = dailyPoints.filter { $0.date >= sevenAgo }.reduce(0) { $0 + $1.spend }
        let totalToday = dailyPoints.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.spend }

        // 30天用量（tokens + requests）
        let usageURL = URL(string: "\(base)/organizations/usage_report/messages?starting_at=\(fmt.string(from: thirtyAgo))&ending_at=\(fmt.string(from: now))&bucket_width=30d")!
        let usageResp: AnthropicUsageResponse = try await URLSession.shared.fetchJSON(
            usageURL, headers: headers(apiKey: apiKey))

        var totalTokens = 0
        var totalReqs = 0
        var topModel = ""
        var topModelTokens = 0

        for item in usageResp.data {
            let tokens = (item.input_tokens?.uncached ?? 0) + (item.output_tokens ?? 0)
            totalTokens += tokens
            totalReqs += item.request_count ?? 0
            if tokens > topModelTokens {
                topModelTokens = tokens
                topModel = item.model ?? ""
            }
        }

        return UsageData(
            todaySpend: totalToday,
            sevenDaySpend: total7,
            thirtyDaySpend: total30,
            todayRequests: dailyPoints.filter { cal.isDateInToday($0.date) }.count,
            thirtyDayTokens: totalTokens,
            thirtyDayRequests: totalReqs,
            topModel: topModel,
            dailySpend: dailyPoints
        )
    }

    private func headers(apiKey: String) -> [String: String] {
        ["x-api-key": apiKey, "anthropic-version": version]
    }
}

// MARK: - Response Models

private struct AnthropicCostResponse: Decodable {
    let data: [CostItem]
    struct CostItem: Decodable {
        let start_time: String
        let cost_usd: String
    }
}

private struct AnthropicUsageResponse: Decodable {
    let data: [UsageItem]
    struct UsageItem: Decodable {
        let model: String?
        let input_tokens: InputTokens?
        let output_tokens: Int?
        let request_count: Int?
        struct InputTokens: Decodable {
            let uncached: Int?
            let cache_read: Int?
            let cache_creation: Int?
        }
    }
}
