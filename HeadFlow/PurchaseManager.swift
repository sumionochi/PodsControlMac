// PurchaseManager.swift
import Foundation
import StoreKit

/// Handles:
/// - 3-day free trial (local, using UserDefaults)
/// - Lifetime unlock via non-consumable IAP
/// - Restoring purchases
@MainActor
final class PurchaseManager: ObservableObject {

    static let shared = PurchaseManager()

    // MARK: - Public state for UI

    /// True if the user has bought the lifetime unlock.
    @Published private(set) var isLifetimeUnlocked: Bool = false

    /// True if we are inside the 3-day trial window.
    @Published private(set) var isInTrial: Bool = false

    /// Number of whole days remaining in the trial (ceil).
    @Published private(set) var trialDaysRemaining: Int = 0

    /// StoreKit product for the lifetime unlock.
    @Published private(set) var lifetimeProduct: Product?

    /// Last user-visible error (if you want to show messages).
    @Published var lastError: String?

    /// Convenience: use this to gate features.
    var hasFullAccess: Bool {
        isLifetimeUnlocked || isInTrial
    }

    // MARK: - Config

    /// MUST match the product you configure in App Store Connect.
    /// Example: In-App Purchase → Non-Consumable → Product ID: "podscontrolmac.lifetime"
    private let lifetimeProductID = "podscontrolmac.lifetime"

    /// Length of the free trial (days).
    private let trialLengthDays: Int = 3

    // MARK: - Persistence keys

    private let keyLifetimeUnlocked = "podscontrolmac.lifetimeUnlocked"
    private let keyTrialStartDate  = "podscontrolmac.trialStartDate"

    // MARK: - Transaction listening

    private var updatesTask: Task<Void, Never>?

    private init() { }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Public entry point

    /// Call once at app launch (e.g. from AppDelegate).
    func start() {
        Task {
        #if DEBUG
        print("🛒 PurchaseManager starting...")
        print("🛒 Product ID: \(lifetimeProductID)")
        #endif
        
        await refreshProducts()
        await refreshPurchasedState()
        updateTrialState()
        startListeningForTransactions()
        
        #if DEBUG
        print("🛒 Trial active: \(isInTrial)")
        print("🛒 Lifetime unlocked: \(isLifetimeUnlocked)")
        print("🛒 Full access: \(hasFullAccess)")
        #endif
        }
    }

    // MARK: - Trial logic

    private func updateTrialState() {
        // Purchased → no trial needed
        if isLifetimeUnlocked {
            isInTrial = false
            trialDaysRemaining = 0
            return
        }

        let defaults = UserDefaults.standard

        // First launch: set trial start now
        let startDate: Date
        if let stored = defaults.object(forKey: keyTrialStartDate) as? Date {
            startDate = stored
        } else {
            let now = Date()
            defaults.set(now, forKey: keyTrialStartDate)
            startDate = now
        }

        let endDate = Calendar.current.date(byAdding: .day,
                                            value: trialLengthDays,
                                            to: startDate) ?? startDate

        let now = Date()
        if now < endDate {
            isInTrial = true
            let remainingSeconds = endDate.timeIntervalSince(now)
            let days = Int(ceil(remainingSeconds / (24 * 60 * 60)))
            trialDaysRemaining = max(1, days)
        } else {
            isInTrial = false
            trialDaysRemaining = 0
        }
    }

    // MARK: - StoreKit: products & entitlements

    private func refreshProducts() async {
        do {
            let storeProducts = try await Product.products(for: [lifetimeProductID])
            lifetimeProduct = storeProducts.first
            if lifetimeProduct == nil {
                print("PurchaseManager: lifetime product not found for ID \(lifetimeProductID)")
            } else {
                print("PurchaseManager: loaded product \(lifetimeProductID)")
            }
        } catch {
            lastError = "Could not load products."
            print("PurchaseManager: Product load error: \(error)")
        }
    }

    /// Checks current entitlements (includes restores) and updates isLifetimeUnlocked.
    private func refreshPurchasedState() async {
        var unlocked = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == lifetimeProductID {
                unlocked = true
                break
            }
        }

        // Also respect the local cache as a fallback
        let cached = UserDefaults.standard.bool(forKey: keyLifetimeUnlocked)
        isLifetimeUnlocked = unlocked || cached

        if isLifetimeUnlocked {
            UserDefaults.standard.set(true, forKey: keyLifetimeUnlocked)
        }

        print("PurchaseManager: lifetime unlocked = \(isLifetimeUnlocked)")
    }

    private func startListeningForTransactions() {
        updatesTask?.cancel()

        updatesTask = Task.detached(priority: .background) { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }

                if transaction.productID == self.lifetimeProductID {
                    await MainActor.run {
                        self.handleVerified(transaction: transaction)
                    }
                }

                await transaction.finish()
            }
        }
    }

    private func handleVerified(transaction: Transaction) {
        guard transaction.productID == lifetimeProductID else { return }

        isLifetimeUnlocked = true
        UserDefaults.standard.set(true, forKey: keyLifetimeUnlocked)

        // Recompute trial (will effectively disable it).
        updateTrialState()

        print("PurchaseManager: lifetime unlock granted via transaction \(transaction.id)")
    }

    // MARK: - Purchase & restore

    /// Call when the user taps "Unlock forever – $9.99".
    func purchaseLifetime() async {
        guard let product = lifetimeProduct else {
            await refreshProducts()
            guard let product2 = lifetimeProduct else {
                lastError = "Unable to load purchase information. Please try again."
                return
            }
            await purchase(product: product2)
            return
        }

        await purchase(product: product)
    }

    private func purchase(product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    handleVerified(transaction: transaction)
                    await transaction.finish()
                    lastError = nil
                } else {
                    lastError = "Unable to verify your purchase. Please try again."
                }

            case .userCancelled:
                lastError = "Purchase was cancelled."
                print("PurchaseManager: User cancelled the purchase")

            case .pending:
                lastError = "Purchase is pending approval. Please check back later."
                print("PurchaseManager: Purchase is pending (e.g., Ask to Buy)")

            @unknown default:
                lastError = "An unexpected error occurred. Please try again."
                print("PurchaseManager: Unknown purchase result")
            }
        } catch {
            lastError = error.localizedDescription
            print("PurchaseManager: purchase error: \(error)")
        }
    }

    /// Optional: for a "Restore Purchases" button.
    func restorePurchases() async {
        for await result in Transaction.all {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == lifetimeProductID {
                handleVerified(transaction: transaction)
            }
        }
    }
}
