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
