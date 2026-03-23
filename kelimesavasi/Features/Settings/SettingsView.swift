import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            List {
                // Profile section
                Section {
                    HStack {
                        Text("Oyuncu Adı")
                            .foregroundStyle(AppTheme.Colors.text)
                        Spacer()
                        TextField("Oyuncu", text: Binding(
                            get: { env.settingsService.playerName },
                            set: { env.settingsService.playerName = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .autocorrectionDisabled()
                    }
                } header: {
                    sectionHeader("Profil")
                }

                // Preferences
                Section {
                    Toggle(isOn: Binding(
                        get: { env.settingsService.hapticEnabled },
                        set: { env.settingsService.hapticEnabled = $0 }
                    )) {
                        Label("Dokunsal Geri Bildirim", systemImage: "hand.tap")
                            .foregroundStyle(AppTheme.Colors.text)
                    }
                    .tint(AppTheme.Colors.primary)

                    Toggle(isOn: Binding(
                        get: { env.settingsService.soundEnabled },
                        set: { env.settingsService.soundEnabled = $0 }
                    )) {
                        Label("Ses Efektleri", systemImage: "speaker.wave.2")
                            .foregroundStyle(AppTheme.Colors.text)
                    }
                    .tint(AppTheme.Colors.primary)
                } header: {
                    sectionHeader("Tercihler")
                }

                // Data
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("İstatistikleri Sıfırla", systemImage: "trash")
                            .foregroundStyle(AppTheme.Colors.error)
                    }
                } header: {
                    sectionHeader("Veri")
                }

                // About
                Section {
                    HStack {
                        Text("Sürüm")
                            .foregroundStyle(AppTheme.Colors.text)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    HStack {
                        Text("Kelime Listesi")
                            .foregroundStyle(AppTheme.Colors.text)
                        Spacer()
                        Text("kelimeler.txt")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                } header: {
                    sectionHeader("Hakkında")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Ayarlar")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)
            }
        }
        .confirmationDialog("İstatistikleri sıfırlamak istediğinden emin misin?",
                            isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button("Sıfırla", role: .destructive) {
                env.statsService.reset()
            }
            Button("İptal", role: .cancel) {}
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.Font.caption(11))
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .textCase(.uppercase)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppEnvironment())
    }
}
