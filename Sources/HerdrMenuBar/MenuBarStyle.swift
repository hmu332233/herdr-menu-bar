import AppKit
import HerdrCore

/// 코어의 플랫폼 중립 모델을 AppKit 시각 요소(NSColor/NSImage/NSAttributedString)로 매핑한다.
@MainActor
enum MenuBarStyle {

    // MARK: - 상태 색상

    static func color(_ status: AgentStatus) -> NSColor {
        switch status {
        case .idle:
            return .secondaryLabelColor
        case .working:
            return .white
        case .blocked:
            return .systemRed
        case .done:
            return NSColor(calibratedRed: 0.65, green: 1.0, blue: 0.35, alpha: 1)
        case .unknown:
            return .tertiaryLabelColor
        }
    }

    // MARK: - 메뉴바 아이콘 (주의 중심: 우선순위 배지 + 카운트)

    /// 우선순위 규칙(코어)이 고른 배지들을 SF Symbol + 숫자로 나열한다.
    /// 보통 1~2쌍(예: `⚠1 ▶2`)만 나와 폭이 좁고, 급한 건(blocked) 빨강으로 먼저.
    static func applyIcon(to button: NSStatusBarButton, counts: StatusCounts) {
        button.image = nil
        button.imagePosition = .noImage
        button.appearsDisabled = false

        let badges = DashboardRender.badges(counts)
        let line = NSMutableAttributedString()
        for (i, badge) in badges.enumerated() {
            if i > 0 { line.append(NSAttributedString(string: "  ")) }
            let tint = menuBarTint(badge.status)
            line.append(symbolGlyph(for: badge.status, tint: tint))
            line.append(NSAttributedString(
                string: " \(badge.count)",
                attributes: [.font: NSFont.menuBarFont(ofSize: 0), .foregroundColor: tint],
            ))
        }
        button.attributedTitle = line
    }

    /// 캐릭터 모드: 에이전트 순서대로 상태 이모지 fallback을 표시한다.
    static func applyCharacters(to button: NSStatusBarButton, agents: [Agent]) {
        button.image = nil
        button.imagePosition = .noImage
        button.appearsDisabled = false
        button.attributedTitle = characterLine(agents)
    }

    private static func characterLine(_ agents: [Agent]) -> NSAttributedString {
        let line = NSMutableAttributedString()
        var remaining = DashboardRender.maxVisibleCharacters
        var appendedGroup = false
        for group in AgentGrouping.byWorkspace(agents) {
            guard remaining > 0 else { break }
            let visibleAgents = Array(group.agents.prefix(remaining))
            guard !visibleAgents.isEmpty else { continue }

            if appendedGroup {
                line.append(characterSeparator(DashboardRender.characterWorkspaceSeparator))
            }

            for (index, agent) in visibleAgents.enumerated() {
                if index > 0 {
                    line.append(characterSeparator(DashboardRender.characterAgentSeparator))
                }
                line.append(characterGlyph(for: agent.agentStatus))
            }

            appendedGroup = true
            remaining -= visibleAgents.count
        }

        let hiddenCount = max(0, agents.count - DashboardRender.maxVisibleCharacters)
        if hiddenCount > 0 {
            line.append(NSAttributedString(
                string: " +\(hiddenCount)",
                attributes: [.font: NSFont.menuBarFont(ofSize: 0)]
            ))
        }
        return line
    }

    private static func characterSeparator(_ value: String) -> NSAttributedString {
        NSAttributedString(
            string: value,
            attributes: [.font: NSFont.menuBarFont(ofSize: 0)]
        )
    }

    private static func characterGlyph(for status: AgentStatus) -> NSAttributedString {
        let tint = menuBarTint(status)
        if let image = characterImage(for: status) {
            return imageGlyph(image, tint: tint)
        }
        return NSAttributedString(
            string: DashboardRender.characterSymbol(status),
            attributes: [.font: NSFont.menuBarFont(ofSize: 0), .foregroundColor: tint]
        )
    }

    private static func menuBarTint(_ status: AgentStatus) -> NSColor {
        switch status {
        case .idle, .unknown:
            return .systemGray
        case .working:
            return .white
        case .blocked:
            return .systemRed
        case .done:
            return NSColor(calibratedRed: 0.65, green: 1.0, blue: 0.35, alpha: 1)
        }
    }

    private static func characterImage(for status: AgentStatus) -> NSImage? {
        for ext in DashboardRender.characterImageExtensions {
            guard let url = Bundle.module.url(
                forResource: "image",
                withExtension: ext,
                subdirectory: "Resources/Characters"
            ) else {
                continue
            }
            if let image = NSImage(contentsOf: url) {
                image.isTemplate = true
                return image
            }
        }
        return nil
    }

    private static func imageGlyph(_ image: NSImage, tint: NSColor) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = tintedImage(image, color: tint)
        attachment.bounds = aspectFitBounds(for: image.size, boxSize: 18)
        let glyph = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        glyph.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 0, length: glyph.length))
        return glyph
    }

    private static func tintedImage(_ image: NSImage, color: NSColor) -> NSImage {
        let tinted = NSImage(size: image.size)
        tinted.lockFocus()
        defer { tinted.unlockFocus() }

        let rect = NSRect(origin: .zero, size: image.size)
        color.setFill()
        rect.fill()
        image.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
        return tinted
    }

    private static func aspectFitBounds(for imageSize: NSSize, boxSize: CGFloat) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(x: 0, y: 0, width: boxSize, height: boxSize)
        }

        let scale = min(boxSize / imageSize.width, boxSize / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: (boxSize - width) / 2,
            y: (NSFont.menuBarFont(ofSize: 0).capHeight - height) / 2,
            width: width,
            height: height
        )
    }

    /// 상태별 SF Symbol 이름.
    private static func symbolName(_ status: AgentStatus) -> String {
        switch status {
        case .blocked: return "exclamationmark.triangle.fill"
        case .working: return "play.fill"
        case .done: return "checkmark.circle.fill"
        case .idle: return "circle"
        case .unknown: return "questionmark.circle"
        }
    }

    /// 틴트된 SF Symbol 1개를 텍스트에 인라인할 attributed string으로.
    private static func symbolGlyph(for status: AgentStatus, tint: NSColor) -> NSAttributedString {
        let pointSize = NSFont.menuBarFont(ofSize: 0).pointSize
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
            .applying(.init(paletteColors: [tint]))
        guard let image = NSImage(systemSymbolName: symbolName(status), accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else {
            // 폴백: 이모지
            return NSAttributedString(
                string: DashboardRender.symbol(status),
                attributes: [.font: NSFont.menuBarFont(ofSize: 0), .foregroundColor: tint]
            )
        }
        let attachment = NSTextAttachment()
        attachment.image = image
        let h = image.size.height
        attachment.bounds = CGRect(x: 0, y: (NSFont.menuBarFont(ofSize: 0).capHeight - h) / 2,
                                   width: image.size.width, height: h)
        return NSAttributedString(attachment: attachment)
    }

    /// herdr 연결 안 됨 — 회색 점선 원 심볼 + 비활성 표시.
    static func applyDisconnected(to button: NSStatusBarButton) {
        let symbol = NSImage(
            systemSymbolName: "circle.dashed",
            accessibilityDescription: "herdr disconnected"
        )
        symbol?.isTemplate = true
        button.image = symbol
        button.imagePosition = .imageOnly
        button.attributedTitle = NSAttributedString(string: "")
        button.appearsDisabled = true
    }

    // MARK: - 드롭다운 항목

    /// 상단 요약 줄 (비클릭, 흐린 소형 글씨).
    static func summaryItem(_ counts: StatusCounts) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: DashboardRender.summaryLine(counts),
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        return item
    }

    /// workspace 그룹 헤더 (비클릭): 작은 대문자 제목 + 흐린 카운트.
    static func headerItem(_ group: WorkspaceGroup) -> NSMenuItem {
        let item = NSMenuItem(title: group.title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        let line = NSMutableAttributedString(
            string: group.title.uppercased(),
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold),
                .foregroundColor: NSColor.tertiaryLabelColor,
                .kern: 0.5,
            ]
        )
        line.append(NSAttributedString(
            string: "  \(group.agents.count)",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular),
                .foregroundColor: NSColor.quaternaryLabelColor,
            ]
        ))
        item.attributedTitle = line
        return item
    }

    /// 에이전트 한 줄: 색상 상태 점 ● + 에이전트 종류 + 흐린 상태 단어.
    /// 클릭하면 target에 action을 보내고, pane id는 representedObject로 전달한다.
    static func agentItem(_ agent: Agent, target: AnyObject?, action: Selector?) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: action, keyEquivalent: "")
        item.target = target
        item.representedObject = agent.paneId
        let menuFont = NSFont.menuFont(ofSize: 0)

        let line = NSMutableAttributedString()
        // 들여쓰기 + 색상 점
        line.append(NSAttributedString(
            string: "    ● ",
            attributes: [.foregroundColor: color(agent.agentStatus), .font: menuFont]
        ))
        // 에이전트 종류
        line.append(NSAttributedString(
            string: agent.agent,
            attributes: [.foregroundColor: NSColor.labelColor, .font: menuFont]
        ))
        // 흐린 상태 단어
        line.append(NSAttributedString(
            string: "  \(DashboardRender.statusWord(agent.agentStatus))",
            attributes: [.foregroundColor: NSColor.tertiaryLabelColor, .font: menuFont]
        ))
        item.attributedTitle = line
        return item
    }
}
