import XCTest
@testable import HerdrCore

/// 실제 herdr 바이너리에 대한 라이브 스모크. herdr 미설치/미실행이면 skip.
final class LiveSmokeTests: XCTestCase {
    func testLiveAgentList() throws {
        let client = AgentListClient()
        let agents: [Agent]
        do {
            agents = try client.list()
        } catch {
            throw XCTSkip("herdr not available: \(error)")
        }
        let counts = StatusCounts(agents)
        print("LIVE OK: \(agents.count) agents")
        print("  badges: \(DashboardRender.badges(counts))")
        for a in agents { print("  line: \(DashboardRender.agentLine(a))") }
    }
}
