import SwiftUI

struct ProviderTabBar: View {
    @EnvironmentObject var vm: DashboardViewModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Provider.allCases) { provider in
                ProviderTab(provider: provider, isSelected: vm.selectedProvider == provider)
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { vm.selectedProvider = provider } }
            }
        }
        .padding(.horizontal, 12)
    }
}

struct ProviderTab: View {
    let provider: Provider
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: provider.icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? provider.color : .gray)
            Text(provider.rawValue)
                .font(.caption2)
                .foregroundColor(isSelected ? .white : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? provider.color.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? provider.color.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}
