import XCTest
@testable import HerdrCore

/// "죽었다 살아나는" 복구를 클라이언트+상태 레벨에서 검증.
/// AppDelegate.poll()의 분기와 동일한 매핑(성공→connected / throw→disconnected)을 재현.
final class RecoveryTests: XCTestCase {

    private func pollState(_ client: AgentListClient) -> DashboardState {
        do { return .connected(try client.list()) }
        catch { return .disconnected }
    }

    func testDisconnectedWhenHerdrAbsent() {
        let down = AgentListClient(binaryPath: "/nonexistent/herdr")
        XCTAssertEqual(pollState(down), .disconnected)
    }

    /// herdr가 살아있으면 자동으로 connected로 복귀 (상태 래치 없음).
    func testRecoversToConnectedWhenHerdrAvailable() throws {
        let live = AgentListClient()   // 실제 herdr
        let state = pollState(live)
        guard case .connected = state else {
            throw XCTSkip("herdr not available for recovery check: \(state)")
        }
        // down → up 전환 시 같은 poll 경로가 곧장 connected를 돌려줌
        XCTAssertEqual(pollState(AgentListClient(binaryPath: "/nonexistent/herdr")), .disconnected)
        if case .connected = pollState(live) {} else { XCTFail("did not recover") }
    }

    func testDisconnectedIconAndMessage() {
        XCTAssertEqual(DashboardRender.disconnectedIcon, "—")
        // 정확한 문구는 언어별이라 LocalizationTests가 본다 — 여기선 비어 있지 않기만.
        XCTAssertFalse(DashboardRender.disconnectedMessage.isEmpty)
    }
}
