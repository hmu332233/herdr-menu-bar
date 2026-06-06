import XCTest
@testable import HerdrCore

final class ClickActionTests: XCTestCase {
    func testCasesAndLabels() {
        XCTAssertEqual(ClickAction.allCases, [.none, .kaku])
        XCTAssertEqual(ClickAction.none.label, "이동 안 함")
        XCTAssertEqual(ClickAction.kaku.label, "kaku로 이동")
    }

    func testRawValueRoundTrip() {
        for mode in ClickAction.allCases {
            XCTAssertEqual(ClickAction(rawValue: mode.rawValue), mode)
        }
        XCTAssertNil(ClickAction(rawValue: "iterm"))   // 미지 값 안전
    }
}
