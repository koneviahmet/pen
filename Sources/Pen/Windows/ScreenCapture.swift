import AppKit
import CoreGraphics

enum ScreenCapture {
    /// `kCGWindowListOptionOnScreenBelowWindow`: alttaki masaüstü / uygulamalar (Pen penceresi hariç).
    static func imageBelowOverlay(overlayWindowNumber: CGWindowID, rectInScreenSpace: CGRect) -> CGImage? {
        guard rectInScreenSpace.width >= 1, rectInScreenSpace.height >= 1 else { return nil }
        return CGWindowListCreateImage(
            rectInScreenSpace,
            .optionOnScreenBelowWindow,
            overlayWindowNumber,
            [.bestResolution, .nominalResolution]
        )
    }

    /// Tüm birleşik ekran dikdörtgeni (NSScreen.frame birlikleri).
    static var combinedScreenFrame: CGRect {
        NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
    }
}
