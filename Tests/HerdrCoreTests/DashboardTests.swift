import XCTest
@testable import HerdrCore

final class DashboardTests: XCTestCase {

    private func fixture(_ name: String) throws -> [Agent] {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: "json")
        )
        return try AgentListDecoder.decode(Data(contentsOf: url))
    }

    func testCountsByStatusIncludingDone() throws {
        let counts = try StatusCounts(fixture("agent_list_mixed_status"))
        XCTAssertEqual(counts.idle, 1)
        XCTAssertEqual(counts.working, 1)
        XCTAssertEqual(counts.blocked, 1)
        XCTAssertEqual(counts.done, 1)      // done도 집계에 포함
        XCTAssertEqual(counts.unknown, 1)
    }

    func testBadgesBlockedAndWorkingBothShown() {
        var c = StatusCounts([]); c.blocked = 1; c.working = 2
        let badges = DashboardRender.badges(c)
        // blocked 먼저, working 다음
        XCTAssertEqual(badges, [
            .init(status: .blocked, count: 1),
            .init(status: .working, count: 2),
        ])
    }

    func testBadgesWorkingOnly() {
        var c = StatusCounts([]); c.working = 3
        XCTAssertEqual(DashboardRender.badges(c), [.init(status: .working, count: 3)])
    }

    func testBadgesFallsBackToDoneWhenNothingUrgent() {
        var c = StatusCounts([]); c.idle = 2; c.done = 1
        // 급한 게 없으면 done 우선 (idle보다)
        XCTAssertEqual(DashboardRender.badges(c), [.init(status: .done, count: 1)])
    }

    func testBadgesFallsBackToIdleTotal() {
        var c = StatusCounts([]); c.idle = 2; c.unknown = 1
        // done도 없으면 idle (+unknown 합산), 0이어도 하나는 표시
        XCTAssertEqual(DashboardRender.badges(c), [.init(status: .idle, count: 3)])
    }

    func testBadgesEmptyShowsZeroIdle() {
        XCTAssertEqual(DashboardRender.badges(StatusCounts([])), [.init(status: .idle, count: 0)])
    }

    func testAgentLineUsesStatusSymbolAndAgentKind() throws {
        let agents = try fixture("agent_list_multi_workspace")
        XCTAssertEqual(DashboardRender.agentLine(agents[2]), "▶ claude")   // working claude
        XCTAssertEqual(DashboardRender.agentLine(agents[4]), "💤 codex")   // idle codex
    }

    func testGroupByWorkspacePreservesOrderAndTitles() throws {
        let groups = try AgentGrouping.byWorkspace(fixture("agent_list_multi_workspace"))

        // wA, wB, wC — basename은 wB/wC가 같지만(herdr-menu-bar) workspace로 분리
        XCTAssertEqual(groups.map(\.workspaceId), ["wA", "wB", "wC"])
        XCTAssertEqual(groups.map(\.title), ["brain", "herdr-menu-bar", "herdr-menu-bar"])
        XCTAssertEqual(groups.map { $0.agents.count }, [2, 1, 2])
        XCTAssertEqual(groups[2].agents.map(\.agent), ["claude", "codex"])
    }

    func testSummaryLine() throws {
        let counts = try StatusCounts(fixture("agent_list_mixed_status"))
        // idle1 working1 blocked1 done1 unknown1 → 총 5
        XCTAssertEqual(DashboardRender.summaryLine(counts, language: .ko), "에이전트 5 · 작업 1 막힘 1 완료 1 대기 1")
        XCTAssertEqual(DashboardRender.summaryLine(counts, language: .en), "5 agents · working 1 blocked 1 done 1 idle 1")
    }

    func testSummaryLineEmpty() {
        XCTAssertEqual(DashboardRender.summaryLine(StatusCounts([]), language: .ko), "에이전트 0")
        XCTAssertEqual(DashboardRender.summaryLine(StatusCounts([]), language: .en), "0 agents")
    }

    func testStatusWord() {
        XCTAssertEqual(DashboardRender.statusWord(.working, language: .ko), "작업 중")
        XCTAssertEqual(DashboardRender.statusWord(.blocked, language: .ko), "막힘")
        XCTAssertEqual(DashboardRender.statusWord(.working, language: .en), "working")
        XCTAssertEqual(DashboardRender.statusWord(.blocked, language: .en), "blocked")
    }

    func testCharacterSymbols() {
        XCTAssertEqual(DashboardRender.characterSymbol(.idle), "😴")
        XCTAssertEqual(DashboardRender.characterSymbol(.working), "🔨")
        XCTAssertEqual(DashboardRender.characterSymbol(.blocked), "😵")
        XCTAssertEqual(DashboardRender.characterSymbol(.done), "✨")
        XCTAssertEqual(DashboardRender.characterSymbol(.unknown), "❔")
    }

    func testCharacterImageLookupPriorityAndBasenames() {
        XCTAssertEqual(DashboardRender.characterImageExtensions, ["png", "webp"])
        XCTAssertEqual(DashboardRender.characterAssetBasename(.idle), "idle")
        XCTAssertEqual(DashboardRender.characterAssetBasename(.working), "working")
        XCTAssertEqual(DashboardRender.characterAssetBasename(.blocked), "blocked")
        XCTAssertEqual(DashboardRender.characterAssetBasename(.done), "done")
        XCTAssertEqual(DashboardRender.characterAssetBasename(.unknown), "unknown")
    }

    func testCharacterLinePreservesAgentListOrder() throws {
        let agents = try fixture("agent_list_mixed_status")

        XCTAssertEqual(DashboardRender.characterLine(agents), "😴 🔨 😵 ✨ ❔")
    }

    func testCharacterLineLimitsVisibleAgentsAndShowsHiddenCountOnly() throws {
        let agents = try fixture("agent_list_mixed_status")
        let sixAgents = agents + [agents[0]]

        XCTAssertEqual(DashboardRender.characterLine(sixAgents), "😴 🔨 😵 ✨ ❔ +1")
    }

    func testCharacterLineSeparatesWorkspaceGroups() throws {
        let agents = try fixture("agent_list_multi_workspace")

        XCTAssertEqual(DashboardRender.characterLine(agents), "😴 😴   🔨   😴 😴")
    }

    func testStatusColorMapping() {
        XCTAssertEqual(StatusColor(.working), .working)
        XCTAssertEqual(StatusColor(.blocked), .blocked)
        XCTAssertEqual(StatusColor(.done), .done)
        XCTAssertEqual(StatusColor(.idle), .idle)
        XCTAssertEqual(StatusColor(.unknown), .unknown)
    }
}
