//
//  HomeView.swift
//  Zysquy — App entry hub.
//
//  Lets the user pick between the two training modules at app start:
//    • NIHSS Assessment — stepwise NIH Stroke Scale with multilingual
//      patient prompts.
//    • Stroke Code Timer — simulated stroke-code workflow (timeline,
//      decision support, dosing, case bank).
//  Education and training only. Not a medical device. Not for clinical
//  decisions.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var languageStore: LanguageStore
    @EnvironmentObject var strokeCodeStore: StrokeCodeStore

    /// Set by `RootView` to swap back to the language selection screen.
    var onChangeLanguage: () -> Void = {}

    /// Module the user has chosen to enter from Home.
    enum Module: Hashable {
        case nihss
        case strokeCode
    }

    @State private var path: [Module] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    moduleCard(
                        title: "NIHSS Assessment",
                        subtitle: "Stepwise NIH Stroke Scale with multilingual patient prompts.",
                        bullets: [
                            "All 11 NIHSS items in order",
                            "Provider instructions + patient prompts",
                            "One-tap scoring with running total",
                            "Encounter history (encrypted on-device)"
                        ],
                        icon: "brain",
                        tint: .red,
                        cta: "Open NIHSS",
                        action: { path.append(.nihss) }
                    )

                    moduleCard(
                        title: "Stroke Code Timer",
                        subtitle: "Simulated stroke-code drills with timeline, decisions, dosing, and a case bank.",
                        bullets: [
                            "Milestones vs. Target: Stroke time goals",
                            "Decision support: imaging, IVT, LVO, EVT",
                            "Weight-based alteplase / tenecteplase dosing",
                            "Educator case bank with debrief"
                        ],
                        icon: "stopwatch",
                        tint: .blue,
                        cta: strokeCodeStore.active == nil ? "Open Stroke Code" : "Resume Stroke Code (LIVE)",
                        ctaTint: strokeCodeStore.active == nil ? .blue : .red,
                        action: { path.append(.strokeCode) }
                    )

                    disclaimerCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Zysquy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onChangeLanguage()
                    } label: {
                        Label(languageStore.selectedLanguage.displayName, systemImage: "globe")
                    }
                }
            }
            .navigationDestination(for: Module.self) { module in
                switch module {
                case .nihss:
                    ContentView()
                case .strokeCode:
                    StrokeCodeTimerView()
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.red.gradient)
            Text("Zysquy")
                .font(.title.bold())
            Text("Stroke training — NIHSS and stroke-code workflow")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Patient language: \(languageStore.selectedLanguage.displayName)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Module card

    private func moduleCard(title: String,
                            subtitle: String,
                            bullets: [String],
                            icon: String,
                            tint: Color,
                            cta: String,
                            ctaTint: Color? = nil,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundStyle(tint.gradient)
                        .frame(width: 48)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(bullets, id: \.self) { b in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(tint)
                            Text(b)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }

                HStack {
                    Spacer()
                    Label(cta, systemImage: "chevron.right")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background((ctaTint ?? tint).opacity(0.15))
                        .foregroundStyle(ctaTint ?? tint)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Disclaimer

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Education and training only")
                    .font(.subheadline.bold())
                Text("Not a medical device. Not for clinical decisions or documentation. Follow your institution's stroke protocol for real patient care.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    HomeView()
        .environmentObject(LanguageStore())
        .environmentObject(StrokeCodeStore())
}
