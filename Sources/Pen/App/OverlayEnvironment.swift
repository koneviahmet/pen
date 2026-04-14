import SwiftUI

private struct OverlayWindowNumberKey: EnvironmentKey {
    static let defaultValue: UInt32 = 0
}

extension EnvironmentValues {
    /// `NSPanel.windowNumber` → `CGWindowListCreateImage` için.
    var overlayWindowNumber: UInt32 {
        get { self[OverlayWindowNumberKey.self] }
        set { self[OverlayWindowNumberKey.self] = newValue }
    }
}
