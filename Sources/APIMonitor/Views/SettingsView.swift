import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var drafts: [Provider: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings").font(.headline).foregroundColor(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }.buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(red: 0.1, green: 0.1, blue: 0.18))

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Provider.allCases) { provider in
                        APIKeyRow(provider: provider,
                                  value: Binding(
                                    get: { drafts[provider] ?? vm.apiKeys[provider] ?? "" },
                                    set: { drafts[provider] = $0 }
                                  ))
                    }
                }
                .padding(16)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.buttonStyle(.plain).foregroundColor(.gray)
                Button("Save") {
                    drafts.forEach { vm.saveAPIKey($0.value, for: $0.key) }
                    dismiss()
                }
                .buttonStyle(.borderedProminent).tint(.blue)
            }
            .padding(16)
            .background(Color(red: 0.08, green: 0.08, blue: 0.14))
        }
        .frame(width: 380, height: 380)
        .background(Color(red: 0.11, green: 0.11, blue: 0.18))
    }
}

struct APIKeyRow: View {
    let provider: Provider
    @Binding var value: String
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: provider.icon).foregroundColor(provider.color).font(.caption)
                Text(provider.rawValue).font(.subheadline).foregroundColor(.white)
            }
            HStack {
                Group {
                    if isRevealed {
                        TextField("API Key", text: $value)
                    } else {
                        SecureField("API Key", text: $value)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .font(.system(.caption, design: .monospaced))

                Button { isRevealed.toggle() } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye").foregroundColor(.gray)
                }.buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
    }
}
