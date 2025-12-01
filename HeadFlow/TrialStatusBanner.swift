//TrialStatusBanner.swift
import SwiftUI

/// Small banner shown at the top of the Overview tab with:
/// - Trial days remaining
/// - Trial ended message
/// - Lifetime unlocked message
struct TrialStatusBanner: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    let onOpenLicenseTab: () -> Void

    var body: some View {
        Group {
            if purchaseManager.isLifetimeUnlocked {
                banner(
                    title: "PodsControlMac is fully unlocked",
                    subtitle: "Thank you for supporting development!",
                    systemImage: "checkmark.seal.fill",
                    tint: .green
                )
            } else if purchaseManager.isInTrial {
                let days = purchaseManager.trialDaysRemaining
                let suffix = (days == 1) ? "day" : "days"

                banner(
                    title: "Free trial: \(days) \(suffix) left",
                    subtitle: "Enjoy all features now. Unlock once to keep using PodsControlMac forever.",
                    systemImage: "clock.badge.checkmark",
                    tint: .accentColor
                )
            } else {
                banner(
                    title: "Trial ended",
                    subtitle: "Head-controlled scrolling, cursor control, and dictation are paused until you unlock PodsControlMac.",
                    systemImage: "lock.fill",
                    tint: .orange
                )
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func banner(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !purchaseManager.isLifetimeUnlocked {
                    HStack(spacing: 8) {
                        Button("Unlock forever – $9.99") {
                            onOpenLicenseTab()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Learn more") {
                            onOpenLicenseTab()
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}
