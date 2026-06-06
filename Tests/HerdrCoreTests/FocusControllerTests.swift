import XCTest
@testable import HerdrCore

final class FocusControllerTests: XCTestCase {

    private let kakuListJSON = Data("""
    [
      {"window_id":0,"tab_id":1,"pane_id":1,"title":"..kspaces/brain"},
      {"window_id":0,"tab_id":0,"pane_id":7,"title":"herdr"},
      {"window_id":0,"tab_id":2,"pane_id":2,"title":"..spaces/skills"}
    ]
    """.utf8)

    func testFindsHerdrPaneByTitle() {
        XCTAssertEqual(KakuPaneFinder.herdrPaneId(fromKakuListJSON: kakuListJSON), 7)
    }

    func testNoHerdrPaneReturnsNil() {
        let json = Data(#"[{"pane_id":1,"title":"zsh"}]"#.utf8)
        XCTAssertNil(KakuPaneFinder.herdrPaneId(fromKakuListJSON: json))
    }

    func testGarbageJSONReturnsNil() {
        XCTAssertNil(KakuPaneFinder.herdrPaneId(fromKakuListJSON: Data("not json".utf8)))
    }
}
