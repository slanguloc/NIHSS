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
    @EnvironmentObject var strokeCodeStore: StrokeCodeStore

    enum Module: Hashable {
        case nihss
        case strokeCode
    }

    @State private var path: [Module] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeHero

                    PatientLanguagePicker(style: .card)

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Training modules")
                        moduleCard(
                            title: "NIHSS Assessment",
                            summary: "Stepwise NIH Stroke Scale with multilingual patient prompts.",
                            highlights: [
                                "All 11 items in order",
                                "TTS + optional speech capture",
                                "Encrypted encounter history"
                            ],
                            icon: "brain",
                            tint: .red,
                            cta: "Open NIHSS",
                            action: { path.append(.nihss) }
                        )
                        moduleCard(
                            title: "Stroke Code Timer",
                            summary: "Simulated stroke-code drills with timeline, decisions, and dosing.",
                            highlights: [
                                "Target: Stroke milestones",
                                "IVT / EVT decision support",
                                "Educator case bank"
                            ],
                            icon: "stopwatch",
                            tint: .blue,
                            cta: strokeCodeStore.active == nil ? "Open Stroke Code" : "Resume (LIVE)",
                            ctaTint: strokeCodeStore.active == nil ? .blue : .red,
                            showLiveBadge: strokeCodeStore.active != nil,
                            action: { path.append(.strokeCode) }
                        )
                    }

                    disclaimerCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Zysquy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PatientLanguagePicker(style: .toolbarIcon)
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

    // MARK: - Welcome

    private var welcomeHero: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 44))
                .foregroundStyle(.red.gradient)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text("Stroke training")
                    .font(.title3.bold())
                Text("NIHSS assessment and simulated stroke-code workflow for education and drills.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    // MARK: - Module card

    private func moduleCard(title: String,
                            summary: String,
                            highlights: [String],
                            icon: String,
                            tint: Color,
                            cta: String,
                            ctaTint: Color? = nil,
                            showLiveBadge: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(tint.gradient)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if showLiveBadge {
                                Text("LIVE")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.15))
                                    .foregroundStyle(.red)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 6) {
                    ForEach(highlights, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }

                HStack {
                    Spacer()
                    Text(cta)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
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
