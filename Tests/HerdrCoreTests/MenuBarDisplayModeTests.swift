import XCTest
@testable import HerdrCore

final class MenuBarDisplayModeTests: XCTestCase {
    func testCasesAndLabels() {
        XCTAssertEqual(MenuBarDisplayMode.allCases, [.summaryBadge, .character])
        XCTAssertEqual(MenuBarDisplayMode.summaryBadge.label, "요약 배지")
        XCTAssertEqual(MenuBarDisplayMode.character.label, "캐릭터")
    }

    func testRawValueRoundTrip() {
        for mode in MenuBarDisplayMode.allCases {
            XCTAssertEqual(MenuBarDisplayMode(rawValue: mode.rawValue), mode)
        }
        XCTAssertNil(MenuBarDisplayMode(rawValue: "compact"))
    }
}
