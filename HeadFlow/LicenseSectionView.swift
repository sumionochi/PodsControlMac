//  LicenseSectionView.swift
import SwiftUI
import StoreKit

struct LicenseSectionView: View {
    @ObservedObject private var purchase = PurchaseManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("License & Upgrade")
                    .font(.title2)
                    .bold()

                Text("PodsControlMac includes a 3-day free trial, then a one-time lifetime unlock.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    if purchase.isLifetimeUnlocked {
                        // ✅ User already owns it
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("You own PodsControlMac forever.")
                                .font(.headline)
                        }

                        Text("Thank you for supporting development! All features are permanently unlocked on this Mac.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        // ⏳ Trial or expired
                        if purchase.isInTrial {
                            HStack(spacing: 8) {
                                Image(systemName: "hourglass")
                                    .foregroundStyle(.yellow)
                                Text("Free trial active")
                                    .font(.headline)
                            }

                            Text("You have **\(purchase.trialDaysRemaining)** day\(purchase.trialDaysRemaining == 1 ? "" : "s") left of your 3-day free trial.")
                                .font(.subheadline)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Trial expired")
                                    .font(.headline)
                            }

                            Text("Your 3-day free trial has ended. Unlock PodsControlMac forever to keep using hands-free control.")
                                .font(.subheadline)
                        }

                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await purchase.purchaseLifetime()
                                }
                            } label: {
                                if let product = purchase.lifetimeProduct {
                                    Text("Unlock forever – \(product.displayPrice)")
                                } else {
                                    Text("Unlock forever – $9.99")
                                }
                            }

                            Button("Restore purchases") {
                                Task {
                                    await purchase.restorePurchases()
                                }
                            }
                        }
                        .padding(.top, 2)
                    }

                    if let error = purchase.lastError, !error.isEmpty {
                        Divider()
                            .padding(.vertical, 4)

                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "info.circle")
                            Text(error)
                                .font(.footnote)
                        }
                        .foregroundStyle(.red)
                    }
                }
                .padding(8)
            }

            Spacer()
        }
        .padding(20)
    }
}

#Preview {
    LicenseSectionView()
        .frame(width: 520, height: 260)
}
