import XCTest
@testable import HerdrCore

final class AgentListDecoderTests: XCTestCase {

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: "json"),
            "fixture \(name).json not found"
        )
        return try Data(contentsOf: url)
    }

    /// 캡처된 실제 `agent list` 응답으로 디코딩을 검증한다.
    func testDecodesRealResponse() throws {
        let agents = try AgentListDecoder.decode(fixture("agent_list"))

        XCTAssertEqual(agents.count, 3)

        let first = agents[0]
        XCTAssertEqual(first.agent, "claude")
        XCTAssertEqual(first.agentStatus, .idle)
        XCTAssertEqual(first.cwd, "/Users/x/brain")
        XCTAssertEqual(first.paneId, "wAAA-1")
        XCTAssertEqual(first.tabId, "wAAA:1")
        XCTAssertEqual(first.workspaceId, "wAAA")

        XCTAssertEqual(agents[2].agentStatus, .working)
        XCTAssertEqual(agents[2].cwd, "/Users/x/herdr-menu-bar")
    }

    /// 정의된 5개 상태가 모두 매핑되고, 미지의 값은 `.unknown`으로 안전 처리된다.
    func testMapsAllStatusesAndUnknownFallback() throws {
        let agents = try AgentListDecoder.decode(fixture("agent_list_mixed_status"))

        XCTAssertEqual(agents.map(\.agentStatus), [
            .idle,
            .working,
            .blocked,
            .done,
            .unknown,   // "reticulating-splines" → unknown
        ])
    }

    /// 디코딩 실패는 호출자에게 throw 된다.
    func testInvalidJSONThrows() {
        let garbage = Data("{ not json".utf8)
        XCTAssertThrowsError(try AgentListDecoder.decode(garbage))
    }

    /// 바이너리가 없으면(herdr 미설치 등) launchFailed로 throw — poll()이 .disconnected로 매핑.
    func testMissingBinaryThrowsLaunchFailed() {
        let client = AgentListClient(binaryPath: "/nonexistent/herdr")
        XCTAssertThrowsError(try client.list()) { error in
            guard case AgentListError.launchFailed = error else {
                return XCTFail("expected launchFailed, got \(error)")
            }
        }
    }
}
