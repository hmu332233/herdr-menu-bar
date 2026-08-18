import Foundation

/// 상태별 에이전트 집계.
public struct StatusCounts: Equatable, Sendable {
    public var idle = 0
    public var working = 0
    public var blocked = 0
    public var done = 0
    public var unknown = 0

    public init(_ agents: [Agent]) {
        for agent in agents {
            switch agent.agentStatus {
            case .idle: idle += 1
            case .working: working += 1
            case .blocked: blocked += 1
            case .done: done += 1
            case .unknown: unknown += 1
            }
        }
    }
}

/// workspace 단위로 묶인 에이전트 그룹. 드롭다운 한 섹션에 대응.
public struct WorkspaceGroup: Equatable, Sendable {
    /// 헤더에 표시할 대표 cwd basename.
    public let title: String
    public let workspaceId: String
    public let agents: [Agent]
}

public enum AgentGrouping {
    /// agent 배열을 workspace_id로 묶는다. 그룹 순서는 첫 등장 순서를 보존한다
    /// (폴링마다 메뉴 순서가 흔들리지 않도록).
    public static func byWorkspace(_ agents: [Agent]) -> [WorkspaceGroup] {
        var order: [String] = []
        var buckets: [String: [Agent]] = [:]
        for agent in agents {
            if buckets[agent.workspaceId] == nil { order.append(agent.workspaceId) }
            buckets[agent.workspaceId, default: []].append(agent)
        }
        return order.map { wsId in
            let members = buckets[wsId]!
            let title = (members[0].cwd as NSString).lastPathComponent
            return WorkspaceGroup(title: title, workspaceId: wsId, agents: members)
        }
    }
}

/// 폴링 1회의 결과 상태. 렌더 분기를 테스트 가능하게 모델링한다.
public enum DashboardState: Equatable, Sendable {
    /// herdr 연결 성공 (에이전트 0개여도 connected).
    case connected([Agent])
    /// herdr 미실행/소켓 실패/파싱 실패 — 연결 안 됨.
    case disconnected
}

public enum DashboardRender {
    /// herdr 연결 안 됨일 때 메뉴바 아이콘.
    public static let disconnectedIcon = "—"
    /// herdr 연결 안 됨일 때 드롭다운 안내.
    /// 표시 언어에 따라 달라지므로 호출 시점에 조회한다.
    public static var disconnectedMessage: String { L10n.Dashboard.disconnected }
    /// 캐릭터 모드에서 메뉴바에 직접 표시할 최대 에이전트 수.
    public static let maxVisibleCharacters = 5
    /// 캐릭터 모드에서 같은 workspace 안의 에이전트 사이 간격.
    public static let characterAgentSeparator = " "
    /// 캐릭터 모드에서 workspace 그룹 사이 간격.
    public static let characterWorkspaceSeparator = "   "
    /// 상태 이미지 검색 우선순위.
    public static let characterImageExtensions = ["png", "webp"]

    /// 메뉴바에 표시할 배지 하나: 상태 + 카운트.
    public struct Badge: Equatable, Sendable {
        public let status: AgentStatus
        public let count: Int
    }

    /// 메뉴바 배지 목록을 우선순위 규칙으로 계산한다 (주의 중심).
    /// - blocked가 있으면 ⚠(빨강) 먼저, working도 있으면 ▶도 함께.
    /// - blocked·working 둘 다 0이면 폴백: done 있으면 ✓, 아니면 idle ○(0이어도).
    /// 0인 상태는 표시하지 않는다(폭·노이즈 최소화).
    public static func badges(_ counts: StatusCounts) -> [Badge] {
        var result: [Badge] = []
        if counts.blocked > 0 { result.append(Badge(status: .blocked, count: counts.blocked)) }
        if counts.working > 0 { result.append(Badge(status: .working, count: counts.working)) }
        if !result.isEmpty { return result }

        // 급한 게 없을 때 폴백 — 하나만.
        if counts.done > 0 { return [Badge(status: .done, count: counts.done)] }
        let total = counts.idle + counts.unknown
        return [Badge(status: .idle, count: total)]
    }

    /// 그룹 내 에이전트 한 줄 라벨: `<상태기호> <에이전트 종류>`.
    /// cwd는 그룹 헤더에 있으므로 줄에서는 에이전트 종류(claude/codex)를 보여준다.
    public static func agentLine(_ agent: Agent) -> String {
        "\(symbol(agent.agentStatus)) \(agent.agent)"
    }

    public static func symbol(_ status: AgentStatus) -> String {
        switch status {
        case .idle: return "💤"
        case .working: return "▶"
        case .blocked: return "⚠"
        case .done: return "✓"
        case .unknown: return "?"
        }
    }

    public static func characterSymbol(_ status: AgentStatus) -> String {
        switch status {
        case .idle: return "😴"
        case .working: return "🔨"
        case .blocked: return "😵"
        case .done: return "✨"
        case .unknown: return "❔"
        }
    }

    public static func characterAssetBasename(_ status: AgentStatus) -> String {
        status.rawValue
    }

    public static func characterLine(_ agents: [Agent]) -> String {
        var remaining = maxVisibleCharacters
        var groupLines: [String] = []
        for group in AgentGrouping.byWorkspace(agents) {
            guard remaining > 0 else { break }
            let visibleAgents = Array(group.agents.prefix(remaining))
            guard !visibleAgents.isEmpty else { continue }
            groupLines.append(
                visibleAgents
                    .map { characterSymbol($0.agentStatus) }
                    .joined(separator: characterAgentSeparator)
            )
            remaining -= visibleAgents.count
        }
        let visible = groupLines.joined(separator: characterWorkspaceSeparator)
        let hiddenCount = max(0, agents.count - maxVisibleCharacters)
        guard hiddenCount > 0 else { return visible }
        return "\(visible) +\(hiddenCount)"
    }

    /// 사람이 읽는 상태 단어 (드롭다운 줄 뒤에 흐리게 표시).
    public static func statusWord(_ status: AgentStatus) -> String {
        switch status {
        case .idle: return L10n.Status.idle
        case .working: return L10n.Status.working
        case .blocked: return L10n.Status.blocked
        case .done: return L10n.Status.done
        case .unknown: return L10n.Status.unknown
        }
    }

    /// 상단 요약 줄: `<총> agents` + 0 아닌 상태 요약.
    public static func summaryLine(_ counts: StatusCounts) -> String {
        let total = counts.idle + counts.working + counts.blocked + counts.done + counts.unknown
        var parts: [String] = []
        if counts.working > 0 { parts.append(L10n.Dashboard.working(counts.working)) }
        if counts.blocked > 0 { parts.append(L10n.Dashboard.blocked(counts.blocked)) }
        if counts.done > 0 { parts.append(L10n.Dashboard.done(counts.done)) }
        if counts.idle > 0 { parts.append(L10n.Dashboard.idle(counts.idle)) }
        let suffix = parts.isEmpty ? "" : " · " + parts.joined(separator: " ")
        return L10n.Dashboard.agents(total) + suffix
    }
}

/// 상태별 색상 역할 (플랫폼 중립). AppKit이 실제 NSColor로 매핑한다.
public enum StatusColor: Equatable, Sendable {
    case working   // 초록
    case blocked   // 빨강
    case done      // 파랑
    case idle      // 회색(보조)
    case unknown   // 회색(보조)

    public init(_ status: AgentStatus) {
        switch status {
        case .working: self = .working
        case .blocked: self = .blocked
        case .done: self = .done
        case .idle: self = .idle
        case .unknown: self = .unknown
        }
    }
}
