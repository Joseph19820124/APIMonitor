import Foundation

struct UsageData {
    var todaySpend: Double = 0
    var sevenDaySpend: Double = 0
    var thirtyDaySpend: Double = 0
    var todayRequests: Int = 0
    var thirtyDayTokens: Int = 0
    var thirtyDayRequests: Int = 0
    var topModel: String = ""
    var dailySpend: [DailyPoint] = []
    var isLoading: Bool = false
    var error: String? = nil

    struct DailyPoint: Identifiable {
        let id = UUID()
        let date: Date
        let spend: Double
    }
}

struct APIKey {
    let provider: Provider
    let value: String
}
