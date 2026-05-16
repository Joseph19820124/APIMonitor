import Foundation

struct MiniMaxService: ProviderService {
    func fetchUsage(apiKey: String) async throws -> UsageData {
        let url = URL(string: "https://api.minimax.io/v1/token_plan/remains")!
        let resp: MiniMaxResponse = try await URLSession.shared.fetchJSON(
            url, headers: ["Authorization": "Bearer \(apiKey)"])

        guard resp.base_resp.status_code == 0 else {
            throw APIError.httpError(resp.base_resp.status_code)
        }

        let u = resp.usage
        let usedTokens = u.tokens_limit - u.remaining_quota

        return UsageData(
            todaySpend: 0,             // MiniMax 不返回费用，只有用量
            sevenDaySpend: 0,
            thirtyDaySpend: Double(u.total_usage_usd ?? "0") ?? 0,
            todayRequests: 0,
            thirtyDayTokens: usedTokens,
            thirtyDayRequests: 0,
            topModel: "MiniMax",
            dailySpend: []
        )
    }
}

private struct MiniMaxResponse: Decodable {
    let base_resp: BaseResp
    let usage: Usage
    struct BaseResp: Decodable { let status_code: Int; let status_msg: String }
    struct Usage: Decodable {
        let total_usage_usd: String?
        let tokens_used: Int?
        let tokens_limit: Int
        let remaining_quota: Int
        let usage_percent: Double?
    }
}
