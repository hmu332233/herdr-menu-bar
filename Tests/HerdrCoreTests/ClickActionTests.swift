import XCTest
@testable import HerdrCore

final class ClickActionTests: XCTestCase {
    func testCasesAndLabels() {
        XCTAssertEqual(ClickAction.allCases, [.none, .kaku])
        // 실제 문구는 표시 언어에 따라 달라진다 — 정확한 번역은 LocalizationTests가 검증한다.
        // 여기서는 라벨이 비어 있지 않고 서로 구분되는지만 본다.
        let labels = ClickAction.allCases.map(\.label)
        XCTAssertFalse(labels.contains(where: \.isEmpty))
        XCTAssertEqual(Set(labels).count, labels.count, "라벨이 중복된다")
    }

    func testRawValueRoundTrip() {
        for mode in ClickAction.allCases {
            XCTAssertEqual(ClickAction(rawValue: mode.rawValue), mode)
        }
        XCTAssertNil(ClickAction(rawValue: "iterm"))   // 미지 값 안전
    }
}
