import AppKit
import SwiftUI

struct MainOverlayView: View {
    @ObservedObject var document: DrawingDocument
    @ObservedObject var appState: AppState

    @State private var currentStrokePoints: [CGPoint] = []
    @State private var activeTextId: UUID?

    /// `DragGesture` ve `Canvas` aynı SwiftUI koordinat uzayını paylaşır (sol üst köken, Y aşağı).
    private static let canvasCoordinateSpaceName = "penCanvas"

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                whiteboardLayer
                    .allowsHitTesting(appState.drawingEnabled)

                Group {
                    if appState.drawingEnabled {
                        AnnotationCanvasLayer(
                            document: document,
                            appState: appState,
                            currentStrokePoints: $currentStrokePoints,
                            activeTextId: $activeTextId,
                            canvasCoordinateSpaceName: Self.canvasCoordinateSpaceName
                        )
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .allowsHitTesting(false)
                    }
                }

                laserLayer
                    .allowsHitTesting(false)

                spotlightLayer
                    .allowsHitTesting(false)

                MouseTrackingRepresentable(enabled: shouldTrackMouse) { point, pressure in
                    appState.lastPressure = max(0.25, pressure)
                    if appState.currentTool == .laser {
                        appState.laserPosition = point
                        var trail = appState.laserTrail
                        trail.append(point)
                        if trail.count > 32 {
                            trail.removeFirst(trail.count - 32)
                        }
                        appState.laserTrail = trail
                    }
                    if appState.spotlightEnabled {
                        appState.spotlightCenter = point
                    }
                }
                .allowsHitTesting(false)

                /// Çizim açık: tam araç çubuğu. Kapalıyken kalem ayrı `NSPanel`de (ana overlay fareyi geçirir).
                Group {
                    if appState.drawingEnabled {
                        FloatingToolbar(document: document, appState: appState, containerSize: geo.size)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.94, anchor: .bottomTrailing).combined(with: .opacity),
                                    removal: .opacity
                                )
                            )
                    }
                }
                .animation(.spring(response: 0.36, dampingFraction: 0.82), value: appState.drawingEnabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 18)
                .padding(.bottom, 18)
                .offset(x: appState.floatingToolbarOffset.width, y: appState.floatingToolbarOffset.height)
                .allowsHitTesting(appState.drawingEnabled)
            }
            .coordinateSpace(name: Self.canvasCoordinateSpaceName)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.clear)
        }
    }

    private var shouldTrackMouse: Bool {
        appState.drawingEnabled
            && (appState.currentTool == .laser || appState.spotlightEnabled)
    }

    @ViewBuilder
    private var whiteboardLayer: some View {
        if appState.drawingEnabled {
            WhiteboardBackgroundLayerContent(background: appState.whiteboard)
        } else {
            // Çizim kapalı: masaüstü görünsün, tıklamalar geçsin (hitTest + şeffaf katman).
            Color.clear
        }
    }

    @ViewBuilder
    private var laserLayer: some View {
        Canvas { context, size in
            guard appState.currentTool == .laser, appState.drawingEnabled else { return }
            for (i, p) in appState.laserTrail.enumerated() {
                let t = CGFloat(i) / CGFloat(max(appState.laserTrail.count, 1))
                let alpha = 0.15 + t * 0.5
                let circle = Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6))
                context.fill(circle, with: .color(Color.red.opacity(alpha)))
            }
            if let lp = appState.laserPosition {
                let outer = Path(ellipseIn: CGRect(x: lp.x - 10, y: lp.y - 10, width: 20, height: 20))
                context.fill(outer, with: .color(Color.red.opacity(0.35)))
                let inner = Path(ellipseIn: CGRect(x: lp.x - 4, y: lp.y - 4, width: 8, height: 8))
                context.fill(inner, with: .color(Color.red))
            }
        }
    }

    @ViewBuilder
    private var spotlightLayer: some View {
        if appState.spotlightEnabled, appState.drawingEnabled {
            GeometryReader { geo in
                let c = appState.spotlightCenter
                let r: CGFloat = 140
                Canvas { context, _ in
                    let whole = Path(CGRect(origin: .zero, size: geo.size))
                    // Önceki 0.55 çok koyuydu; Spotlight açıkken hafif kararma.
                    context.fill(whole, with: .color(Color.black.opacity(0.38)))
                    context.blendMode = .destinationOut
                    let hole = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                    context.fill(hole, with: .color(.white))
                }
                .compositingGroup()
            }
            .allowsHitTesting(false)
        }
    }
}
