//
//  LanguageSelectionView.swift
//  NIHSS Stroke Scale — Select patient language at start.
//

import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject var languageStore: LanguageStore
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 56))
                    .foregroundStyle(.red.gradient)
                Text("Select patient language")
                    .font(.title2.bold())
                Text("Choose the language for patient prompts and audio")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)

            List {
                ForEach(AppLanguage.visibleToUser) { lang in
                    Button {
                        languageStore.selectedLanguage = lang
                        languageStore.markLanguageSelectionCompleted()
                        onComplete()
                    } label: {
                        HStack {
                            Text(lang.displayName)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            if languageStore.selectedLanguage == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .scrollContentBackground(.hidden)

            Spacer(minLength: 4)
        }
    }
}
