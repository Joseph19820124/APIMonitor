import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                Text("API Monitor")
                    .font(.headline).foregroundColor(.white)
                Spacer()
                Button { vm.showSettings.toggle() } label: {
                    Image(systemName: "gearshape.fill").foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                Button { Task { await vm.refreshAll() } } label: {
                    Image(systemName: "arrow.clockwise").foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(red: 0.1, green: 0.1, blue: 0.18))

            // Provider Tabs
            ProviderTabBar()
                .padding(.top, 8)

            // 主内容
            if vm.currentUsage.isLoading {
                Spacer()
                ProgressView().scaleEffect(0.8).tint(.white)
                Spacer()
            } else if let err = vm.currentUsage.error {
                ErrorView(message: err, provider: vm.selectedProvider)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        StatsCardView()
                        SpendChartView()
                    }
                    .padding(12)
                }
            }

            // 底部
            HStack {
                Image(systemName: "clock.fill").foregroundColor(.gray).font(.caption2)
                Text("Updated just now").font(.caption2).foregroundColor(.gray)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .font(.caption2).foregroundColor(.gray).buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color(red: 0.08, green: 0.08, blue: 0.14))
        }
        .frame(width: 380)
        .background(Color(red: 0.11, green: 0.11, blue: 0.18))
        .sheet(isPresented: $vm.showSettings) { SettingsView() }
    }
}

struct ErrorView: View {
    let message: String
    let provider: Provider
    @EnvironmentObject var vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill").font(.largeTitle).foregroundColor(.orange)
            Text(message).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
            Button("Configure API Key") { vm.showSettings = true }
                .buttonStyle(.borderedProminent).tint(provider.color)
        }
        .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
