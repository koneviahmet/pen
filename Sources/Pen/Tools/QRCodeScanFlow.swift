import AppKit
import CoreImage
import Vision

enum QRCodeScanFlow {
    struct ScanResult {
        let value: String?
        let message: String?
    }

    @MainActor
    private static var activeSelectionWindow: SelectionWindow?

    @MainActor
    static func start(overlayWindowNumber: CGWindowID, completion: @escaping (ScanResult) -> Void) {
        activeSelectionWindow?.close()
        let flow = SelectionWindow(overlayWindowNumber: overlayWindowNumber) { result in
            activeSelectionWindow = nil
            completion(result)
        }
        activeSelectionWindow = flow
        flow.present()
    }
}

@MainActor
private final class SelectionWindow {
    private let panel: NSPanel
    private let selectionView: QRSelectionView
    private let screenFrame: CGRect
    private static let ciContext = CIContext(options: nil)

    init(overlayWindowNumber: CGWindowID, completion: @escaping (QRCodeScanFlow.ScanResult) -> Void) {
        let frame = ScreenCapture.combinedScreenFrame
        screenFrame = frame
        panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        panel.hasShadow = false
        panel.isMovable = false

        selectionView = QRSelectionView(frame: CGRect(origin: .zero, size: frame.size), screenFrame: frame)
        selectionView.onFinished = { [weak panel] selectedRect, cancelled in
            panel?.orderOut(nil)
            if cancelled {
                completion(.init(value: nil, message: nil))
                return
            }
            guard let selectedRect else {
                completion(.init(value: nil, message: "Geçerli bir seçim yapılamadı."))
                return
            }
            if let payload = Self.decodeQR(
                overlayWindowNumber: overlayWindowNumber,
                selectedRect: selectedRect,
                screenBounds: frame
            ) {
                completion(.init(value: payload, message: nil))
            } else {
                completion(.init(value: nil, message: "Seçilen alanda QR kod bulunamadı."))
            }
        }
        panel.contentView = selectionView
    }

    func present() {
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel.orderOut(nil)
    }

    private static func decodeQR(
        overlayWindowNumber: CGWindowID,
        selectedRect: CGRect,
        screenBounds: CGRect
    ) -> String? {
        let maxSide = max(selectedRect.width, selectedRect.height)
        let paddings: [CGFloat] = [0, maxSide * 0.08, maxSide * 0.16, maxSide * 0.28]

        for padding in paddings {
            let candidateRect = selectedRect.insetBy(dx: -padding, dy: -padding).intersection(screenBounds)
            guard candidateRect.width >= 12, candidateRect.height >= 12 else { continue }
            guard let image = ScreenCapture.imageBelowOverlay(
                overlayWindowNumber: overlayWindowNumber,
                rectInScreenSpace: candidateRect
            ) else {
                continue
            }
            if let value = decodeEnhanced(from: image) {
                return value
            }
        }
        return nil
    }

    private static func decodeEnhanced(from image: CGImage) -> String? {
        if let value = decodeWithVision(image: image) {
            return value
        }
        if let value = decodeWithCoreImage(image: image) {
            return value
        }
        let ci = CIImage(cgImage: image)
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: 2, y: 2))
        if let scaledCG = ciContext.createCGImage(scaled, from: scaled.extent) {
            if let value = decodeWithVision(image: scaledCG) {
                return value
            }
            if let value = decodeWithCoreImage(image: scaledCG) {
                return value
            }
        }
        return nil
    }

    private static func decodeWithVision(image: CGImage) -> String? {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            let firstPayload = (request.results ?? [])
                .sorted { a, b in
                    let ac = a.boundingBox.centerDistanceToUnitCenter
                    let bc = b.boundingBox.centerDistanceToUnitCenter
                    return ac < bc
                }
                .compactMap { $0.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
            return firstPayload
        } catch {
            return nil
        }
    }

    private static func decodeWithCoreImage(image: CGImage) -> String? {
        let ciImage = CIImage(cgImage: image)
        guard let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        ) else {
            return nil
        }
        let features = detector.features(in: ciImage)
        let center = CGPoint(x: ciImage.extent.midX, y: ciImage.extent.midY)
        let sorted = features.compactMap { $0 as? CIQRCodeFeature }.sorted {
            let da = hypot($0.bounds.midX - center.x, $0.bounds.midY - center.y)
            let db = hypot($1.bounds.midX - center.x, $1.bounds.midY - center.y)
            return da < db
        }
        for qr in sorted {
            if let value = qr.messageString?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }
        return nil
    }
}

private extension CGRect {
    var centerDistanceToUnitCenter: CGFloat {
        let cx = midX - 0.5
        let cy = midY - 0.5
        return hypot(cx, cy)
    }
}

private final class QRSelectionView: NSView {
    var onFinished: ((CGRect?, Bool) -> Void)?

    private let screenFrame: CGRect
    private var dragStartScreenPoint: CGPoint?
    private var dragCurrentScreenPoint: CGPoint?

    init(frame frameRect: NSRect, screenFrame: CGRect) {
        self.screenFrame = screenFrame
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onFinished?(nil, true)
            return
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        let p = NSEvent.mouseLocation
        dragStartScreenPoint = p
        dragCurrentScreenPoint = p
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        dragCurrentScreenPoint = NSEvent.mouseLocation
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        dragCurrentScreenPoint = NSEvent.mouseLocation
        let rect = normalizedSelectionRect()
        if let rect, rect.width >= 20, rect.height >= 20 {
            onFinished?(rect, false)
        } else {
            onFinished?(nil, false)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.28).setFill()
        dirtyRect.fill()

        guard let screenRect = normalizedSelectionRect() else { return }
        let localRect = CGRect(
            x: screenRect.origin.x - screenFrame.origin.x,
            y: screenRect.origin.y - screenFrame.origin.y,
            width: screenRect.width,
            height: screenRect.height
        )
        NSColor.clear.setFill()
        localRect.fill(using: .clear)

        NSColor.white.withAlphaComponent(0.95).setStroke()
        let path = NSBezierPath(rect: localRect)
        path.lineWidth = 2
        path.stroke()
    }

    private func normalizedSelectionRect() -> CGRect? {
        guard let start = dragStartScreenPoint, let current = dragCurrentScreenPoint else { return nil }
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let maxX = max(start.x, current.x)
        let maxY = max(start.y, current.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
