import AppKit
import SwiftUI

/// Dikey minimal araç çubuğu — varsayılan **sağ alt**; üst tutamaktan sürüklenir; kısa dokunuş çizimi kapatır.
struct FloatingToolbar: View {
    @ObservedObject var document: DrawingDocument
    @ObservedObject var appState: AppState
    /// Tam ekran overlay boyutu (sürükleme sınırları için).
    var containerSize: CGSize
    @Environment(\.overlayWindowNumber) private var overlayWindowNumber

    @State private var penFlyoutExpanded = false
    @State private var lineArrowFlyoutExpanded = false
    @State private var shapeFlyoutExpanded = false
    @State private var colorFlyoutExpanded = false
    @State private var whiteboardFlyoutExpanded = false
    @State private var toolbarGestureOrigin: CGSize?

    private let spring = Animation.spring(response: 0.34, dampingFraction: 0.82)

    var body: some View {
        VStack(spacing: 8) {
            toolbarDragHandle
            toolbarDivider

            penFamilyCluster
            toolButton(.eraserStroke)
            lineArrowFamilyCluster
            shapeFamilyCluster
            toolButton(.text)
            toolButton(.select)

            toolbarDivider

            colorFamilyCluster

            toolbarDivider

            whiteboardFamilyCluster

            toolbarDivider

            Button {
                document.undo()
            } label: {
                Image(systemName: ToolbarChrome.undo)
                    .font(ToolbarChrome.toolbarIconFont)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(document.canUndo ? ToolbarChrome.iconOnBar : ToolbarChrome.iconOnBarMuted)
                    .frame(width: 38, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!document.canUndo)
            .help("Geri al")

            moreMenu
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .background(toolbarCapsuleBackground)
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
        .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 14)
        .fixedSize(horizontal: true, vertical: true)
        .onChange(of: appState.currentTool) { _, _ in
            colorFlyoutExpanded = false
            whiteboardFlyoutExpanded = false
        }
    }

    private var toolbarCapsuleBackground: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(ToolbarChrome.darkBarFill)
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [ToolbarChrome.barHighlightTop, Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.55)
                    )
                )
                .blendMode(.plusLighter)
                .opacity(0.85)
        }
    }

    private var toolbarDivider: some View {
        Capsule(style: .continuous)
            .fill(ToolbarChrome.dividerColor)
            .frame(width: 26, height: 1)
            .padding(.vertical, 1)
    }

    private var toolbarDragHandle: some View {
        VStack(spacing: 3) {
            Capsule(style: .continuous)
                .fill(ToolbarChrome.dragGripColor.opacity(0.55))
                .frame(width: 22, height: 3)
            Capsule(style: .continuous)
                .fill(ToolbarChrome.dragGripColor.opacity(0.35))
                .frame(width: 16, height: 3)
        }
        .frame(height: 22)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .highPriorityGesture(toolbarDragGesture)
            .help("Taşı")
    }

    private var toolbarDragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if toolbarGestureOrigin == nil {
                    toolbarGestureOrigin = appState.floatingToolbarOffset
                }
                guard let origin = toolbarGestureOrigin else { return }
                let next = CGSize(
                    width: origin.width + value.translation.width,
                    height: origin.height + value.translation.height
                )
                appState.floatingToolbarOffset = ToolbarOffsetClamp.clamp(next, containerSize: containerSize)
            }
            .onEnded { value in
                let origin = toolbarGestureOrigin
                let d = hypot(value.translation.width, value.translation.height)
                toolbarGestureOrigin = nil
                if d < ToolbarOffsetClamp.tapVsDragThreshold {
                    if let o = origin {
                        appState.floatingToolbarOffset = o
                    }
                    withAnimation(.easeInOut(duration: 0.22)) {
                        appState.drawingEnabled = false
                    }
                } else {
                    AppPreferences.floatingToolbarOffset = appState.floatingToolbarOffset
                }
            }
    }

    /// Kalem / kurşun / fosforlu: şekil paletiyle aynı; yan tarafta yatay seçim.
    private var penFamilyCluster: some View {
        let inFamily = appState.currentTool.isBrushToolFamily
        let mainSelected = inFamily
        let mainIcon = inFamily ? appState.currentTool.systemImage : DrawingTool.pen.systemImage
        let openRight = shapeFlyoutOpenTowardTrailing

        return Button {
            if appState.currentTool.isBrushToolFamily {
                withAnimation(spring) {
                    penFlyoutExpanded.toggle()
                    lineArrowFlyoutExpanded = false
                    shapeFlyoutExpanded = false
                    colorFlyoutExpanded = false
                    whiteboardFlyoutExpanded = false
                }
            } else {
                withAnimation(spring) {
                    penFlyoutExpanded = false
                    lineArrowFlyoutExpanded = false
                    appState.currentTool = .pen
                    shapeFlyoutExpanded = false
                    colorFlyoutExpanded = false
                    whiteboardFlyoutExpanded = false
                }
            }
        } label: {
            ZStack {
                if mainSelected {
                    Circle()
                        .fill(ToolbarChrome.selectionCircleFill)
                        .frame(width: 30, height: 30)
                }
                Image(systemName: mainIcon)
                    .font(ToolbarChrome.toolbarIconFont)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(mainSelected ? ToolbarChrome.selectionIconOnCircle : ToolbarChrome.iconOnBar)
            }
            .frame(width: 38, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(inFamily ? appState.currentTool.tooltipTitle : DrawingTool.pen.tooltipTitle)
        .overlay(alignment: Alignment(horizontal: openRight ? .trailing : .leading, vertical: .center)) {
            if penFlyoutExpanded {
                penFlyoutPanel(openToTrailing: openRight)
                    .offset(x: flyoutBesideOffsetX(estimatedWidth: penFlyoutEstimatedWidth, openToTrailing: openRight))
                    .transition(
                        .move(edge: openRight ? .leading : .trailing)
                            .combined(with: .opacity)
                    )
            }
        }
        .zIndex(penFlyoutExpanded ? 20 : 0)
        .onChange(of: appState.currentTool) { _, new in
            if !new.isBrushToolFamily {
                penFlyoutExpanded = false
            }
        }
    }

    /// Çizgi ve ok — kapalı şekiller paletiyle aynı davranış.
    private var lineArrowFamilyCluster: some View {
        let inFamily = appState.currentTool.isLineArrowFamily
        let mainSelected = inFamily
        let mainIcon = inFamily ? appState.currentTool.systemImage : DrawingTool.shapeLine.systemImage
        let openRight = shapeFlyoutOpenTowardTrailing

        return Button {
            if appState.currentTool.isLineArrowFamily {
                withAnimation(spring) {
                    lineArrowFlyoutExpanded.toggle()
                    penFlyoutExpanded = false
                    shapeFlyoutExpanded = false
                    colorFlyoutExpanded = false
                    whiteboardFlyoutExpanded = false
                }
            } else {
                withAnimation(spring) {
                    penFlyoutExpanded = false
                    shapeFlyoutExpanded = false
                    appState.currentTool = .shapeLine
                    lineArrowFlyoutExpanded = false
                    colorFlyoutExpanded = false
                    whiteboardFlyoutExpanded = false
                }
            }
        } label: {
            ZStack {
                if mainSelected {
                    Circle()
                        .fill(ToolbarChrome.selectionCircleFill)
                        .frame(width: 30, height: 30)
                }
                Image(systemName: mainIcon)
                    .font(ToolbarChrome.toolbarIconFont)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(mainSelected ? ToolbarChrome.selectionIconOnCircle : ToolbarChrome.iconOnBar)
            }
            .frame(width: 38, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(inFamily ? appState.currentTool.tooltipTitle : DrawingTool.shapeLine.tooltipTitle)
        .overlay(alignment: Alignment(horizontal: openRight ? .trailing : .leading, vertical: .center)) {
            if lineArrowFlyoutExpanded {
                lineArrowFlyoutPanel(openToTrailing: openRight)
                    .offset(x: flyoutBesideOffsetX(estimatedWidth: lineArrowFlyoutEstimatedWidth, openToTrailing: openRight))
                    .transition(
                        .move(edge: openRight ? .leading : .trailing)
                            .combined(with: .opacity)
                    )
            }
        }
        .zIndex(lineArrowFlyoutExpanded ? 20 : 0)
        .onChange(of: appState.currentTool) { _, new in
            if !new.isLineArrowFamily {
                lineArrowFlyoutExpanded = false
            }
        }
    }

    /// Kapalı şekiller: palet kartın dışında; **boş tarafa** doğru (ekranın solunda isen sağa, sağında isen sola).
    private var shapeFamilyCluster: some View {
        let inFamily = appState.currentTool.isClosedShapeFamily
        let mainSelected = inFamily
        let mainIcon = inFamily ? appState.currentTool.systemImage : DrawingTool.shapeRect.systemImage
        let openRight = shapeFlyoutOpenTowardTrailing

        return Button {
            if appState.currentTool.isClosedShapeFamily {
                withAnimation(spring) {
                    shapeFlyoutExpanded.toggle()
                    penFlyoutExpanded = false
                    lineArrowFlyoutExpanded = false
                    colorFlyoutExpanded = false
                    whiteboardFlyoutExpanded = false
                }
            } else {
                withAnimation(spring) {
                    penFlyoutExpanded = false
                    lineArrowFlyoutExpanded = false
                    appState.currentTool = .shapeRect
                    shapeFlyoutExpanded = false
                    colorFlyoutExpanded = false
                    whiteboardFlyoutExpanded = false
                }
            }
        } label: {
            ZStack {
                if mainSelected {
                    Circle()
                        .fill(ToolbarChrome.selectionCircleFill)
                        .frame(width: 30, height: 30)
                }
                Image(systemName: mainIcon)
                    .font(ToolbarChrome.toolbarIconFont)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(mainSelected ? ToolbarChrome.selectionIconOnCircle : ToolbarChrome.iconOnBar)
            }
            .frame(width: 38, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(inFamily ? appState.currentTool.tooltipTitle : DrawingTool.shapeRect.tooltipTitle)
        .overlay(alignment: Alignment(horizontal: openRight ? .trailing : .leading, vertical: .center)) {
            if shapeFlyoutExpanded {
                shapeFlyoutPanel(openToTrailing: openRight)
                    .offset(x: flyoutBesideOffsetX(estimatedWidth: shapeFlyoutEstimatedWidth, openToTrailing: openRight))
                    .transition(
                        .move(edge: openRight ? .leading : .trailing)
                            .combined(with: .opacity)
                    )
            }
        }
        .zIndex(shapeFlyoutExpanded ? 20 : 0)
        .onChange(of: appState.currentTool) { _, new in
            if !new.isClosedShapeFamily {
                shapeFlyoutExpanded = false
            }
        }
    }

    /// Renk: ana düğmede önizleme; tıklanınca yan palet (hazır + son 5 + özel).
    private var colorFamilyCluster: some View {
        let openRight = shapeFlyoutOpenTowardTrailing
        return Button {
            withAnimation(spring) {
                colorFlyoutExpanded.toggle()
                penFlyoutExpanded = false
                lineArrowFlyoutExpanded = false
                shapeFlyoutExpanded = false
                whiteboardFlyoutExpanded = false
            }
        } label: {
            ZStack {
                if colorFlyoutExpanded {
                    Circle()
                        .fill(ToolbarChrome.selectionCircleFill)
                        .frame(width: 30, height: 30)
                }
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(appState.strokeColor)
                    .frame(width: 26, height: 26)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(ToolbarChrome.barEdgeStroke, lineWidth: 1)
                    )
            }
            .frame(width: 38, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Renk")
        .overlay(alignment: Alignment(horizontal: openRight ? .trailing : .leading, vertical: .center)) {
            if colorFlyoutExpanded {
                colorFlyoutPanel(openToTrailing: openRight)
                    .offset(x: flyoutBesideOffsetX(estimatedWidth: colorFlyoutEstimatedWidth, openToTrailing: openRight))
                    .transition(
                        .move(edge: openRight ? .leading : .trailing)
                            .combined(with: .opacity)
                    )
            }
        }
        .zIndex(colorFlyoutExpanded ? 22 : 0)
        .onChange(of: colorFlyoutExpanded) { _, open in
            if !open {
                appState.pushRecentStrokeColor(appState.strokeColor)
            }
        }
    }

    /// Tahta arka planı: renk paletiyle aynı — ana düğmede güncel seçim ikonu; tıklanınca yan palet.
    private var whiteboardFamilyCluster: some View {
        let openRight = shapeFlyoutOpenTowardTrailing
        return Button {
            withAnimation(spring) {
                whiteboardFlyoutExpanded.toggle()
                penFlyoutExpanded = false
                lineArrowFlyoutExpanded = false
                shapeFlyoutExpanded = false
                colorFlyoutExpanded = false
            }
        } label: {
            ZStack {
                if whiteboardFlyoutExpanded {
                    Circle()
                        .fill(ToolbarChrome.selectionCircleFill)
                        .frame(width: 30, height: 30)
                }
                Image(systemName: appState.whiteboard.systemImage)
                    .font(ToolbarChrome.toolbarIconFont)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(
                        whiteboardFlyoutExpanded
                            ? ToolbarChrome.selectionIconOnCircle
                            : ToolbarChrome.iconOnBar
                    )
            }
            .frame(width: 38, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(appState.whiteboard.tooltipTitle)
        .overlay(alignment: Alignment(horizontal: openRight ? .trailing : .leading, vertical: .center)) {
            if whiteboardFlyoutExpanded {
                whiteboardFlyoutPanel(openToTrailing: openRight)
                    .offset(
                        x: flyoutBesideOffsetX(
                            estimatedWidth: whiteboardFlyoutEstimatedWidth,
                            openToTrailing: openRight
                        )
                    )
                    .transition(
                        .move(edge: openRight ? .leading : .trailing)
                            .combined(with: .opacity)
                    )
            }
        }
        .zIndex(whiteboardFlyoutExpanded ? 21 : 0)
    }

    /// Kaydırmalı palet genişliği (sütun sayısı × hücre + padding).
    private var whiteboardFlyoutEstimatedWidth: CGFloat { 248 }

    private func whiteboardFlyoutPanel(openToTrailing: Bool) -> some View {
        let corner: CGFloat = 16
        let columns = Array(repeating: GridItem(.fixed(36), spacing: 6), count: 5)

        return ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(WhiteboardBackground.allCases) { b in
                    let subSelected = appState.whiteboard == b
                    Button {
                        withAnimation(spring) {
                            appState.whiteboard = b
                            whiteboardFlyoutExpanded = false
                            penFlyoutExpanded = false
                            lineArrowFlyoutExpanded = false
                            shapeFlyoutExpanded = false
                            colorFlyoutExpanded = false
                        }
                    } label: {
                        ZStack {
                            if subSelected {
                                Circle()
                                    .fill(ToolbarChrome.selectionCircleFill)
                                    .frame(width: 30, height: 30)
                            }
                            Image(systemName: b.systemImage)
                                .font(.system(size: 15, weight: .medium))
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(
                                    subSelected ? ToolbarChrome.selectionIconOnCircle : ToolbarChrome.iconOnBar
                                )
                        }
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(b.tooltipTitle)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .frame(width: 228, height: min(340, CGFloat((WhiteboardBackground.allCases.count + 4) / 5) * 44 + 16))
        .scrollBounceBehavior(.basedOnSize)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(ToolbarChrome.darkPanelFill)
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ToolbarChrome.barHighlightTop.opacity(0.72), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blendMode(.plusLighter)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(ToolbarChrome.barEdgeStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
        .shadow(
            color: .black.opacity(0.4),
            radius: 16,
            x: openToTrailing ? 6 : -6,
            y: 10
        )
    }

    /// Kapsül yatay genişlik: padding 8 + 38 + 8 (yaklaşık).
    private var toolbarCardWidth: CGFloat { 54 }
    private var mainToolbarTrailingPadding: CGFloat { 18 }

    /// Ekranda kartın solundaki boşluk mu büyük sağındaki mi; palet geniş tarafa açılır.
    private var shapeFlyoutOpenTowardTrailing: Bool {
        let w = containerSize.width
        let ox = appState.floatingToolbarOffset.width
        let trailingX = w - mainToolbarTrailingPadding + ox
        let leadingX = trailingX - toolbarCardWidth
        let spaceRight = w - trailingX
        let spaceLeft = leadingX
        return spaceRight > spaceLeft
    }

    private var shapeFlyoutBesideGap: CGFloat { 8 }

    private func flyoutBesideOffsetX(estimatedWidth: CGFloat, openToTrailing: Bool) -> CGFloat {
        let d = estimatedWidth + shapeFlyoutBesideGap
        return openToTrailing ? d : -d
    }

    private var shapeFlyoutEstimatedWidth: CGFloat {
        flyoutEstimatedWidth(toolCount: DrawingTool.closedShapeFamily.count)
    }

    /// Kalem ikonları + dikey ayırıcı + yatay kalınlık (− / önizleme / + / sayı).
    private var penFlyoutEstimatedWidth: CGFloat {
        let brush = flyoutEstimatedWidth(toolCount: DrawingTool.brushToolFamily.count)
        let gap: CGFloat = 6
        let divider: CGFloat = 1
        let strokeCluster: CGFloat = 26 + 4 + 68 + 4 + 26 + 4 + 26
        return brush + gap + divider + gap + strokeCluster
    }

    private var lineArrowFlyoutEstimatedWidth: CGFloat {
        flyoutEstimatedWidth(toolCount: DrawingTool.lineArrowFamily.count)
    }

    /// Hazır ızgarası + son renkler + özel satırı için yan panel genişliği.
    private var colorFlyoutEstimatedWidth: CGFloat { 276 }

    private func flyoutEstimatedWidth(toolCount: Int) -> CGFloat {
        let n = CGFloat(toolCount)
        let slot: CGFloat = 30
        let spacing: CGFloat = 6
        let padH: CGFloat = 10 * 2
        return n * slot + max(0, n - 1) * spacing + padH
    }

    /// Kalem ailesi: çizgi/ok paletiyle aynı yatay kapsül — araçlar + yatay kalınlık.
    private func penFlyoutPanel(openToTrailing: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(DrawingTool.brushToolFamily, id: \.rawValue) { t in
                let subSelected = appState.currentTool == t
                Button {
                    withAnimation(spring) {
                        appState.currentTool = t
                        penFlyoutExpanded = false
                        colorFlyoutExpanded = false
                        whiteboardFlyoutExpanded = false
                    }
                } label: {
                    ZStack {
                        if subSelected {
                            Circle()
                                .fill(ToolbarChrome.selectionCircleFill)
                                .frame(width: 26, height: 26)
                        }
                        Image(systemName: t.systemImage)
                            .font(.system(size: 14, weight: .medium))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(subSelected ? ToolbarChrome.selectionIconOnCircle : ToolbarChrome.iconOnBar)
                    }
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(t.tooltipTitle)
            }
            Capsule(style: .continuous)
                .fill(ToolbarChrome.dividerColor)
                .frame(width: 1, height: 22)
            strokeWidthControlHorizontal
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                Capsule(style: .continuous)
                    .fill(ToolbarChrome.darkPanelFill)
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ToolbarChrome.barHighlightTop.opacity(0.7), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blendMode(.plusLighter)
            }
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(ToolbarChrome.barEdgeStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
        .shadow(
            color: .black.opacity(0.4),
            radius: 16,
            x: openToTrailing ? 6 : -6,
            y: 10
        )
    }

    /// Çizgi / ok yatay paleti.
    private func lineArrowFlyoutPanel(openToTrailing: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(DrawingTool.lineArrowFamily, id: \.rawValue) { t in
                let subSelected = appState.currentTool == t
                Button {
                    withAnimation(spring) {
                        appState.currentTool = t
                        lineArrowFlyoutExpanded = false
                        colorFlyoutExpanded = false
                        whiteboardFlyoutExpanded = false
                    }
                } label: {
                    ZStack {
                        if subSelected {
                            Circle()
                                .fill(ToolbarChrome.selectionCircleFill)
                                .frame(width: 26, height: 26)
                        }
                        Image(systemName: t.systemImage)
                            .font(.system(size: 14, weight: .medium))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(subSelected ? ToolbarChrome.selectionIconOnCircle : ToolbarChrome.iconOnBar)
                    }
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(t.tooltipTitle)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                Capsule(style: .continuous)
                    .fill(ToolbarChrome.darkPanelFill)
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ToolbarChrome.barHighlightTop.opacity(0.7), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blendMode(.plusLighter)
            }
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(ToolbarChrome.barEdgeStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
        .shadow(
            color: .black.opacity(0.4),
            radius: 16,
            x: openToTrailing ? 6 : -6,
            y: 10
        )
    }

    /// Şekil paleti: ana çubukla aynı koyu dilim + yatay ikon sırası, seçim beyaz daire.
    private func shapeFlyoutPanel(openToTrailing: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(DrawingTool.closedShapeFamily, id: \.rawValue) { t in
                let subSelected = appState.currentTool == t
                Button {
                    withAnimation(spring) {
                        appState.currentTool = t
                        shapeFlyoutExpanded = false
                        colorFlyoutExpanded = false
                        whiteboardFlyoutExpanded = false
                    }
                } label: {
                    ZStack {
                        if subSelected {
                            Circle()
                                .fill(ToolbarChrome.selectionCircleFill)
                                .frame(width: 26, height: 26)
                        }
                        Image(systemName: t.systemImage)
                            .font(.system(size: 14, weight: .medium))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(subSelected ? ToolbarChrome.selectionIconOnCircle : ToolbarChrome.iconOnBar)
                    }
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(t.tooltipTitle)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                Capsule(style: .continuous)
                    .fill(ToolbarChrome.darkPanelFill)
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ToolbarChrome.barHighlightTop.opacity(0.7), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blendMode(.plusLighter)
            }
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(ToolbarChrome.barEdgeStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
        .shadow(
            color: .black.opacity(0.4),
            radius: 16,
            x: openToTrailing ? 6 : -6,
            y: 10
        )
    }

    /// Tahta / sunum için sık kullanılan hazır renkler.
    private static let presetStrokeColors: [Color] = [
        .black,
        Color(red: 0.22, green: 0.22, blue: 0.24),
        Color(red: 0.85, green: 0.2, blue: 0.18),
        Color(red: 1, green: 0.55, blue: 0.12),
        Color(red: 1, green: 0.85, blue: 0.2),
        Color(red: 0.2, green: 0.72, blue: 0.35),
        Color(red: 0.15, green: 0.65, blue: 0.85),
        Color(red: 0.2, green: 0.4, blue: 0.95),
        Color(red: 0.55, green: 0.35, blue: 0.95),
        Color(red: 1, green: 0.35, blue: 0.55),
        Color(red: 0.55, green: 0.38, blue: 0.24),
        Color(white: 1),
    ]

    private func colorFlyoutPanel(openToTrailing: Bool) -> some View {
        let corner: CGFloat = 16
        let grid = Array(repeating: GridItem(.fixed(28), spacing: 8), count: 6)
        let currentHex = appState.strokeColor.rgbaHexString()

        return VStack(alignment: .leading, spacing: 10) {
            Text("Hazır renkler")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ToolbarChrome.iconOnBarMuted)
            LazyVGrid(columns: grid, spacing: 8) {
                ForEach(Array(Self.presetStrokeColors.enumerated()), id: \.offset) { _, c in
                    colorPresetSwatch(
                        c,
                        selected: c.rgbaHexString() == currentHex
                    ) {
                        appState.selectStrokeColor(c)
                    }
                }
            }
            Capsule(style: .continuous)
                .fill(ToolbarChrome.dividerColor)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Text("Son renkler")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ToolbarChrome.iconOnBarMuted)
            HStack(spacing: 8) {
                ForEach(0 ..< 5, id: \.self) { i in
                    if i < appState.recentStrokeColors.count {
                        let c = appState.recentStrokeColors[i]
                        colorPresetSwatch(
                            c,
                            selected: c.rgbaHexString() == currentHex
                        ) {
                            appState.selectStrokeColor(c)
                        }
                    } else {
                        Circle()
                            .strokeBorder(ToolbarChrome.barEdgeStroke.opacity(0.35), lineWidth: 1)
                            .frame(width: 28, height: 28)
                    }
                }
            }
            Capsule(style: .continuous)
                .fill(ToolbarChrome.dividerColor)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            HStack(spacing: 10) {
                Text("Özel renk")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(ToolbarChrome.iconOnBar.opacity(0.95))
                Spacer(minLength: 8)
                ColorPicker("", selection: $appState.strokeColor, supportsOpacity: true)
                    .labelsHidden()
            }
        }
        .frame(width: 248)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(ToolbarChrome.darkPanelFill)
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ToolbarChrome.barHighlightTop.opacity(0.72), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blendMode(.plusLighter)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(ToolbarChrome.barEdgeStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
        .shadow(
            color: .black.opacity(0.4),
            radius: 16,
            x: openToTrailing ? 6 : -6,
            y: 10
        )
    }

    private func colorPresetSwatch(_ color: Color, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color)
                    .frame(width: 28, height: 28)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(color.isLightSwatch ? 0.35 : 0),
                        lineWidth: color.isLightSwatch ? 1 : 0
                    )
                    .frame(width: 28, height: 28)
                if selected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(ToolbarChrome.selectionIconOnCircle, lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toolButton(_ tool: DrawingTool) -> some View {
        let selected = appState.currentTool == tool
        return Button {
            appState.currentTool = tool
        } label: {
            ZStack {
                if selected {
                    Circle()
                        .fill(ToolbarChrome.selectionCircleFill)
                        .frame(width: 30, height: 30)
                }
                Image(systemName: tool.systemImage)
                    .font(ToolbarChrome.toolbarIconFont)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(selected ? ToolbarChrome.selectionIconOnCircle : ToolbarChrome.iconOnBar)
            }
            .frame(width: 38, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tool.tooltipTitle)
    }

    /// Kalınlık (1…36): yatay, yan paletle uyumlu — − / önizleme / + / değer.
    private var strokeWidthControlHorizontal: some View {
        let w = appState.strokeWidth
        let previewW = min(56, max(22, 16 + w * 1.1))
        let previewH = min(12, max(3, w * 0.38))

        return HStack(spacing: 4) {
            Button {
                appState.strokeWidth = max(1, w - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ToolbarChrome.iconOnBar.opacity(0.95))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(w <= 1)
            .opacity(w <= 1 ? 0.35 : 1)
            .help("Azalt")

            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(ToolbarChrome.swatchWellFill)
                    .frame(width: previewW + 8, height: 24)
                Capsule(style: .continuous)
                    .fill(appState.strokeColor)
                    .frame(width: previewW, height: previewH)
            }
            .frame(height: 26)
            .help("Kalınlık")

            Button {
                appState.strokeWidth = min(36, w + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ToolbarChrome.iconOnBar.opacity(0.95))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(w >= 36)
            .opacity(w >= 36 ? 0.35 : 1)
            .help("Artır")

            Text("\(Int(w))")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ToolbarChrome.iconOnBarMuted)
                .frame(minWidth: 22, alignment: .trailing)
        }
    }

    private var moreMenu: some View {
        Menu {
            Section("Araçlar") {
                toolMenuItem(.select)
                toolMenuItem(.eraserPixel)
                toolMenuItem(.laser)
            }
            Section("Katman") {
                Toggle("Spotlight (ekranı karartır)", isOn: $appState.spotlightEnabled)
                    .disabled(!appState.drawingEnabled)
                    .help("Spotlight")
                Toggle("Büyüteç", isOn: $appState.magnifierEnabled)
                    .disabled(!appState.drawingEnabled)
                    .help("Büyüteç")
            }
            Section("Çizim") {
                Toggle("Bu katmanda çizim", isOn: $appState.drawingEnabled)
                    .help("Çizim")
                Picker("Kalınlık", selection: $appState.strokeWidth) {
                    Text("1 pt").tag(CGFloat(1))
                    Text("2 pt").tag(CGFloat(2))
                    Text("4 pt").tag(CGFloat(4))
                    Text("6 pt").tag(CGFloat(6))
                    Text("8 pt").tag(CGFloat(8))
                    Text("12 pt").tag(CGFloat(12))
                    Text("18 pt").tag(CGFloat(18))
                    Text("24 pt").tag(CGFloat(24))
                    Text("36 pt").tag(CGFloat(36))
                }
                .help("Kalınlık")
                Button("İleri al") {
                    document.redo()
                }
                .disabled(!document.canRedo)
                .help("İleri al")
                Button("Tümünü temizle") {
                    document.clearAll()
                }
                .help("Temizle")
            }
            Section("Dışa aktar") {
                Button("PNG olarak kaydet…") {
                    ImageExport.savePanel(
                        document: document,
                        appState: appState,
                        overlayWindowNumber: overlayWindowNumber
                    )
                }
                .help("PNG")
            }
        } label: {
            Image(systemName: ToolbarChrome.more)
                .font(ToolbarChrome.toolbarIconFont)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(ToolbarChrome.iconOnBarMuted)
                .frame(width: 38, height: 34)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .help("Menü")
    }

    private func toolMenuItem(_ tool: DrawingTool) -> some View {
        Button {
            appState.currentTool = tool
        } label: {
            Label(tool.label, systemImage: tool.systemImage)
        }
        .help(tool.tooltipTitle)
    }
}

/// Çizim kapalıyken ekranda yalnız bu kalem ikonu; dokununca çizim açılır, sürüklenince konum taşınır.
/// Sürükleme `PenFloaterDragNSView` (AppKit, ekran koordinatı) ile — küçük pencerede SwiftUI jesti güvenilir değil.
struct MinimalPenFloater: View {
    @ObservedObject var appState: AppState
    var containerSize: CGSize

    var body: some View {
        ZStack {
            Image(systemName: (appState.currentTool.isBrushToolFamily ? appState.currentTool : .pen).systemImage)
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(ToolbarChrome.iconOnBar)
                .frame(width: 50, height: 50)
                .background(
                    ZStack {
                        Circle()
                            .fill(ToolbarChrome.darkBarFill)
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ToolbarChrome.barHighlightTop.opacity(0.9), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .blendMode(.plusLighter)
                            .opacity(0.75)
                    }
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.08),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 10)
                .allowsHitTesting(false)

            PenFloaterDragRepresentable(appState: appState, containerSize: containerSize)
                .frame(width: 50, height: 50)
        }
        .help((appState.currentTool.isBrushToolFamily ? appState.currentTool : .pen).tooltipTitle)
    }
}
