import SwiftUI
import Charts

struct SpendChartView: View {
    @EnvironmentObject var vm: DashboardViewModel

    var points: [UsageData.DailyPoint] { vm.currentUsage.dailySpend }
    var color: Color { vm.selectedProvider.color }
    var isCodex: Bool { vm.selectedProvider == .codex }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isCodex ? "30-day Tokens" : "30-day Spend")
                .font(.caption).foregroundColor(.gray)

            if points.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 120)
                    .overlay(Text("No data").foregroundColor(.gray).font(.caption))
            } else {
                Chart(points) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value(isCodex ? "Tokens" : "Spend", point.spend)
                    )
                    .foregroundStyle(color.gradient)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(isCodex ? shortTokens(Int(v)) : shortUSD(v))
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .frame(height: 120)
                .chartBackground { _ in Color.clear }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    private func shortUSD(_ v: Double) -> String {
        if v >= 1000 { return "$\(Int(v/1000))k" }
        return "$\(Int(v))"
    }

    private func shortTokens(_ v: Int) -> String {
        if v >= 1_000_000_000 { return "\(v / 1_000_000_000)B" }
        if v >= 1_000_000 { return "\(v / 1_000_000)M" }
        if v >= 1_000 { return "\(v / 1_000)K" }
        return "\(v)"
    }
}
