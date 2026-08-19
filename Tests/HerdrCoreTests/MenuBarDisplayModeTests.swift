import XCTest
@testable import HerdrCore

final class MenuBarDisplayModeTests: XCTestCase {
    func testCasesAndLabels() {
        XCTAssertEqual(MenuBarDisplayMode.allCases, [.summaryBadge, .character])
        // 실제 문구는 표시 언어에 따라 달라진다 — 정확한 번역은 LocalizationTests가 검증한다.
        let labels = MenuBarDisplayMode.allCases.map(\.label)
        XCTAssertFalse(labels.contains(where: \.isEmpty))
        XCTAssertEqual(Set(labels).count, labels.count, "라벨이 중복된다")
    }

    func testRawValueRoundTrip() {
        for mode in MenuBarDisplayMode.allCases {
            XCTAssertEqual(MenuBarDisplayMode(rawValue: mode.rawValue), mode)
        }
        XCTAssertNil(MenuBarDisplayMode(rawValue: "compact"))
    }
}
