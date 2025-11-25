//HeadphoneDeviceState
import Foundation

/// Shared state describing the currently connected headphone device
/// (if any). This is intentionally simple; we can expand it later
/// to include more detailed battery info when available.
final class HeadphoneDeviceState: ObservableObject {

    static let shared = HeadphoneDeviceState()

    enum Kind {
        case none
        case airPods
        case beats
        case other
    }

    @Published var isConnected: Bool = false
    @Published var deviceName: String? = nil
    @Published var kind: Kind = .none

    /// Optional battery percentages. These may be nil if we can't
    /// reliably read them on macOS.
    @Published var batteryLeft: Int? = nil
    @Published var batteryRight: Int? = nil
    @Published var batteryCase: Int? = nil
}
