//
//  PatientLanguagePicker.swift
//  Zysquy — Switch patient language from anywhere in the app.
//
//  Education and training only. Updates LanguageStore (persisted on-device).
//

import SwiftUI

/// Globe menu or chip row for choosing the patient-facing language.
struct PatientLanguagePicker: View {
    @EnvironmentObject var languageStore: LanguageStore

    enum Style {
        /// Toolbar: globe icon only, opens a menu.
        case toolbarIcon
        /// Toolbar: globe + current language name.
        case toolbarLabeled
        /// Home screen: labeled card with selectable chips.
        case card
    }

    var style: Style = .toolbarIcon

    var body: some View {
        switch style {
        case .toolbarIcon:
            languageMenu {
                Image(systemName: "globe")
                    .font(.body.weight(.medium))
            }
        case .toolbarLabeled:
            languageMenu {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text(languageStore.selectedLanguage.displayName)
                        .font(.subheadline)
                }
            }
        case .card:
            cardPicker
        }
    }

    // MARK: - Menu (toolbar)

    private func languageMenu<MenuLabel: View>(@ViewBuilder label: () -> MenuLabel) -> some View {
        Menu {
            ForEach(AppLanguage.visibleToUser) { lang in
                Button {
                    select(lang)
                } label: {
                    if languageStore.selectedLanguage == lang {
                        SwiftUI.Label(lang.displayName, systemImage: "checkmark")
                    } else {
                        Text(lang.displayName)
                    }
                }
            }
        } label: {
            label()
        }
        .accessibilityLabel("Patient language, \(languageStore.selectedLanguage.displayName)")
        .accessibilityHint("Opens menu to change patient language")
    }

    // MARK: - Card (home)

    private var cardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Patient language", systemImage: "globe")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Text("Patient prompts, text-to-speech, and speech recognition use this language. You can change it anytime.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(AppLanguage.visibleToUser) { lang in
                    languageChip(lang)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func languageChip(_ lang: AppLanguage) -> some View {
        let selected = languageStore.selectedLanguage == lang
        return Button {
            select(lang)
        } label: {
            Text(lang.displayName)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Color.red.opacity(0.18) : Color(.tertiarySystemFill))
                .foregroundStyle(selected ? Color.red : Color.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? Color.red : Color.clear, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func select(_ lang: AppLanguage) {
        languageStore.selectedLanguage = lang
        languageStore.markLanguageSelectionCompleted()
    }
}

#Preview("Card") {
    PatientLanguagePicker(style: .card)
        .padding()
        .environmentObject(LanguageStore())
}

#Preview("Toolbar") {
    NavigationStack {
        Text("Content")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PatientLanguagePicker(style: .toolbarIcon)
                }
            }
    }
    .environmentObject(LanguageStore())
}
