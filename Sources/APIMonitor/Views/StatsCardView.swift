import SwiftUI

struct StatsCardView: View {
    @EnvironmentObject var vm: DashboardViewModel

    var usage: UsageData { vm.currentUsage }
    var color: Color { vm.selectedProvider.color }

    var body: some View {
        VStack(spacing: 0) {
            // 主卡片：今日 + 7天
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today").font(.caption).foregroundColor(.gray)
                    Text(formatUSD(usage.todaySpend))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("30d spend").font(.caption).foregroundColor(.gray).padding(.top, 4)
                    Text(formatUSD(usage.thirtyDaySpend))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("7d spend").font(.caption).foregroundColor(.gray)
                    Text(formatUSD(usage.sevenDaySpend))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Today req").font(.caption).foregroundColor(.gray).padding(.top, 4)
                    Text(formatCount(usage.todayRequests))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.25), lineWidth: 1))
            )

            // 底部统计行
            HStack(spacing: 0) {
                StatPill(label: "30d tokens", value: formatTokens(usage.thirtyDayTokens))
                Divider().frame(height: 24).background(Color.white.opacity(0.1))
                StatPill(label: "30d requests", value: formatCount(usage.thirtyDayRequests))
                if !usage.topModel.isEmpty {
                    Divider().frame(height: 24).background(Color.white.opacity(0.1))
                    StatPill(label: "Top model", value: shortModelName(usage.topModel))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
            .padding(.top, 8)
        }
    }

    private func formatUSD(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "$%.2fM", v / 1_000_000) }
        if v >= 1_000 { return String(format: "$%.1fK", v / 1_000) }
        return String(format: "$%.2f", v)
    }

    private func formatCount(_ v: Int) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", Double(v) / 1_000_000) }
        if v >= 1_000 { return "\(v / 1000)K" }
        return "\(v)"
    }

    private func formatTokens(_ v: Int) -> String {
        if v >= 1_000_000_000 { return String(format: "%.1fB", Double(v) / 1e9) }
        if v >= 1_000_000 { return String(format: "%.0fM", Double(v) / 1e6) }
        return formatCount(v)
    }

    private func shortModelName(_ name: String) -> String {
        name.components(separatedBy: "-").prefix(3).joined(separator: "-")
    }
}

struct StatPill: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
