import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var selectedProvider: Provider = .anthropic
    @Published var usageMap: [Provider: UsageData] = [:]
    @Published var apiKeys: [Provider: String] = [:]
    @Published var showSettings = false

    private let services: [Provider: any ProviderService] = [
        .anthropic: AnthropicService(),
        .minimax:   MiniMaxService(),
        .zai:       ZAIService()
    ]

    init() {
        Provider.allCases.forEach { provider in
            apiKeys[provider] = KeychainStore.load(for: provider.keychainKey) ?? ""
            usageMap[provider] = UsageData()
        }
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for provider in Provider.allCases {
                group.addTask { await self.refresh(provider: provider) }
            }
        }
    }

    func refresh(provider: Provider) async {
        guard let key = apiKeys[provider], !key.isEmpty else {
            usageMap[provider] = UsageData(error: "API Key not configured")
            return
        }
        usageMap[provider]?.isLoading = true
        do {
            let data = try await services[provider]!.fetchUsage(apiKey: key)
            usageMap[provider] = data
        } catch {
            usageMap[provider] = UsageData(error: error.localizedDescription)
        }
    }

    func saveAPIKey(_ key: String, for provider: Provider) {
        apiKeys[provider] = key
        KeychainStore.save(key, for: provider.keychainKey)
        Task { await refresh(provider: provider) }
    }

    var currentUsage: UsageData {
        usageMap[selectedProvider] ?? UsageData()
    }
}
