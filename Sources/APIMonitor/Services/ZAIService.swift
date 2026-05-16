import Foundation

// z.ai 没有官方用量 API，做客户端累计追踪
struct ZAIService: ProviderService {
    func fetchUsage(apiKey: String) async throws -> UsageData {
        // 尝试请求一次 balance 接口，验证 key 是否有效
        let url = URL(string: "https://api.z.ai/api/paas/v4/models")!
        let _: ZAIModelsResponse = try await URLSession.shared.fetchJSON(
            url, headers: ["Authorization": "Bearer \(apiKey)"])

        // 从本地缓存读取累计数据
        let cached = ZAILocalTracker.load()
        return UsageData(
            todaySpend: cached.todaySpend,
            sevenDaySpend: cached.sevenDaySpend,
            thirtyDaySpend: cached.thirtyDaySpend,
            todayRequests: cached.todayRequests,
            thirtyDayTokens: cached.thirtyDayTokens,
            thirtyDayRequests: cached.thirtyDayRequests,
            topModel: cached.topModel,
            dailySpend: cached.dailySpend
        )
    }
}

// 本地追踪器（当 z.ai 通过 API 调用时，调用方负责更新此记录）
struct ZAILocalTracker {
    private static let key = "APIMonitor_ZAI_stats"

    static func load() -> UsageData {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stats = try? JSONDecoder().decode(ZAIStats.self, from: data)
        else { return UsageData(topModel: "glm-4", dailySpend: []) }

        return UsageData(
            todaySpend: stats.todaySpend,
            sevenDaySpend: stats.sevenDaySpend,
            thirtyDaySpend: stats.thirtyDaySpend,
            todayRequests: stats.todayRequests,
            thirtyDayTokens: stats.thirtyDayTokens,
            thirtyDayRequests: stats.thirtyDayRequests,
            topModel: stats.topModel,
            dailySpend: []
        )
    }

    struct ZAIStats: Codable {
        var todaySpend: Double = 0
        var sevenDaySpend: Double = 0
        var thirtyDaySpend: Double = 0
        var todayRequests: Int = 0
        var thirtyDayTokens: Int = 0
        var thirtyDayRequests: Int = 0
        var topModel: String = "glm-4"
    }
}

private struct ZAIModelsResponse: Decodable {
    let data: [ZAIModel]?
    struct ZAIModel: Decodable { let id: String }
}
