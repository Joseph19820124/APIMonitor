import Foundation

struct CodexService: ProviderService {
    private let fileManager = FileManager.default

    func fetchUsage(apiKey: String) async throws -> UsageData {
        try verifyCodexLogin()

        guard fileManager.fileExists(atPath: stateDatabaseURL.path) else {
            return emptyUsage()
        }

        async let dailyRows = runSQLite("""
            select date(created_at,'unixepoch','localtime') day,
                   count(*),
                   coalesce(sum(tokens_used), 0)
            from threads
            where created_at >= strftime('%s','now','localtime','start of day','-29 days','utc')
            group by day
            order by day;
            """)
        async let todayRow = runSQLite("""
            select count(*), coalesce(sum(tokens_used), 0)
            from threads
            where created_at >= strftime('%s','now','localtime','start of day','utc');
            """)
        async let sevenDayRow = runSQLite("""
            select count(*), coalesce(sum(tokens_used), 0)
            from threads
            where created_at >= strftime('%s','now','localtime','start of day','-6 days','utc');
            """)
        async let thirtyDayRow = runSQLite("""
            select count(*), coalesce(sum(tokens_used), 0)
            from threads
            where created_at >= strftime('%s','now','localtime','start of day','-29 days','utc');
            """)
        async let topModelRow = runSQLite("""
            select coalesce(nullif(model, ''), 'Codex') model
            from threads
            where created_at >= strftime('%s','now','localtime','start of day','-29 days','utc')
            group by model
            order by coalesce(sum(tokens_used), 0) desc
            limit 1;
            """)

        let dailySpend = try await parseDailyRows(dailyRows)
        let today = try await parseCountAndTokens(todayRow)
        let sevenDay = try await parseCountAndTokens(sevenDayRow)
        let thirtyDay = try await parseCountAndTokens(thirtyDayRow)
        let topModel = try await topModelRow
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? "Codex"

        return UsageData(
            todaySpend: Double(today.tokens),
            sevenDaySpend: Double(sevenDay.tokens),
            thirtyDaySpend: Double(thirtyDay.tokens),
            todayRequests: today.count,
            thirtyDayTokens: thirtyDay.tokens,
            thirtyDayRequests: thirtyDay.count,
            topModel: topModel,
            dailySpend: dailySpend
        )
    }

    private var authURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/auth.json")
    }

    private var stateDatabaseURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/state_5.sqlite")
    }

    private func verifyCodexLogin() throws {
        guard let data = try? Data(contentsOf: authURL),
              let auth = try? JSONDecoder().decode(CodexAuth.self, from: data),
              auth.hasLogin
        else {
            throw APIError.notLoggedIn("Codex login not found. Run codex login once, then refresh.")
        }
    }

    private func runSQLite(_ sql: String) async throws -> String {
        try await Task.detached {
            let process = Process()
            let output = Pipe()
            let error = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
            process.arguments = [stateDatabaseURL.path, "-separator", "|", sql]
            process.standardOutput = output
            process.standardError = error

            do {
                try process.run()
            } catch {
                throw APIError.serviceMessage("Could not read local Codex usage database.")
            }

            process.waitUntilExit()

            let data = output.fileHandleForReading.readDataToEndOfFile()
            let errorData = error.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""
            let errorText = String(data: errorData, encoding: .utf8) ?? ""

            guard process.terminationStatus == 0 else {
                throw APIError.serviceMessage(
                    errorText.isEmpty ? "Could not read local Codex usage database." : errorText
                )
            }

            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
    }

    private func parseDailyRows(_ text: String) -> [UsageData.DailyPoint] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"

        return text
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let parts = line.split(separator: "|", omittingEmptySubsequences: false)
                guard parts.count == 3,
                      let date = formatter.date(from: String(parts[0])),
                      let tokens = Int(parts[2])
                else { return nil }

                return UsageData.DailyPoint(date: date, spend: Double(tokens))
            }
    }

    private func parseCountAndTokens(_ text: String) -> (count: Int, tokens: Int) {
        guard let line = text.split(whereSeparator: \.isNewline).first else {
            return (0, 0)
        }

        let parts = line.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return (0, 0) }

        return (Int(parts[0]) ?? 0, Int(parts[1]) ?? 0)
    }

    private func emptyUsage() -> UsageData {
        UsageData(
            todaySpend: 0,
            sevenDaySpend: 0,
            thirtyDaySpend: 0,
            todayRequests: 0,
            thirtyDayTokens: 0,
            thirtyDayRequests: 0,
            topModel: "Codex",
            dailySpend: []
        )
    }
}

private struct CodexAuth: Decodable {
    let tokens: Tokens?

    var hasLogin: Bool {
        guard let tokens else { return false }
        return !(tokens.accessToken ?? "").isEmpty || !(tokens.accountID ?? "").isEmpty
    }

    struct Tokens: Decodable {
        let accessToken: String?
        let accountID: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case accountID = "account_id"
        }
    }
}
