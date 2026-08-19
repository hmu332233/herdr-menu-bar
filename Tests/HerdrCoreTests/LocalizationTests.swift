import XCTest
@testable import HerdrCore

/// 번역 리소스 자체를 검증한다.
///
/// 런타임 언어에 좌우되지 않도록 `.lproj` 번들을 직접 열어 조회한다.
/// 언어를 추가하면 `translatedLanguages`에 한 줄만 더하면 된다 —
/// 키 누락/오타는 `testEveryLanguageCoversEveryKey`가 잡아낸다.
final class LocalizationTests: XCTestCase {
    /// 저장소에 들어 있는 모든 번역. 새 언어는 여기에 추가한다.
    private static let translatedLanguages = ["en", "ko"]

    /// 기준 언어. 다른 모든 언어는 이 키 집합을 그대로 채워야 한다.
    private static let baseLanguage = "en"

    // MARK: - 기준 언어(en) 실제 문구

    func testEnglishValues() throws {
        let en = try bundle("en")
        XCTAssertEqual(en.string("menu.noAgents"), "No agents")
        XCTAssertEqual(en.string("menu.quit"), "Quit")
        XCTAssertEqual(en.string("menu.display"), "Menu bar display")
        XCTAssertEqual(en.string("menu.clickAction"), "Click action")
        XCTAssertEqual(en.string("display.summaryBadge"), "Summary badge")
        XCTAssertEqual(en.string("display.character"), "Character")
        XCTAssertEqual(en.string("click.none"), "Do nothing")
        XCTAssertEqual(en.string("click.kaku"), "Focus in kaku")
        XCTAssertEqual(en.string("status.idle"), "Idle")
        XCTAssertEqual(en.string("status.working"), "Working")
        XCTAssertEqual(en.string("status.blocked"), "Blocked")
        XCTAssertEqual(en.string("status.done"), "Done")
        XCTAssertEqual(en.string("status.unknown"), "Unknown")
        XCTAssertEqual(en.string("dashboard.disconnected"), "herdr not connected")
    }

    /// 영어는 1개일 때 단수형이어야 한다 — `.stringsdict` 복수형 규칙 검증.
    func testEnglishPluralizesAgentCount() throws {
        let en = try bundle("en")
        XCTAssertEqual(en.plural("dashboard.agents", 0), "0 agents")
        XCTAssertEqual(en.plural("dashboard.agents", 1), "1 agent")
        XCTAssertEqual(en.plural("dashboard.agents", 5), "5 agents")
    }

    /// 한국어는 수와 무관하게 한 가지 형태만 쓴다.
    func testKoreanHasSinglePluralForm() throws {
        let ko = try bundle("ko")
        XCTAssertEqual(ko.plural("dashboard.agents", 1), "에이전트 1")
        XCTAssertEqual(ko.plural("dashboard.agents", 5), "에이전트 5")
    }

    // MARK: - 언어 간 정합성

    /// 모든 언어가 기준 언어와 똑같은 키 집합을 가져야 한다.
    /// 번역을 추가하다 키를 빠뜨리면 여기서 실패한다.
    func testEveryLanguageCoversEveryKey() throws {
        let baseKeys = try keys(inStringsFileFor: Self.baseLanguage)
        XCTAssertFalse(baseKeys.isEmpty, "기준 언어에 키가 하나도 없다")

        for language in Self.translatedLanguages where language != Self.baseLanguage {
            let translated = try keys(inStringsFileFor: language)
            XCTAssertEqual(
                translated, baseKeys,
                "\(language).lproj 키 불일치 — "
                + "누락: \(baseKeys.subtracting(translated).sorted()), "
                + "잉여: \(translated.subtracting(baseKeys).sorted())"
            )
        }
    }

    /// 어떤 언어에서도 빈 문자열이 남아 있으면 안 된다.
    func testNoLanguageHasEmptyValues() throws {
        for language in Self.translatedLanguages {
            let table = try stringsTable(for: language)
            for (key, value) in table where value.trimmingCharacters(in: .whitespaces).isEmpty {
                XCTFail("\(language).lproj: \"\(key)\" 값이 비어 있다")
            }
        }
    }

    /// `%d`를 쓰는 키는 모든 언어에서 똑같이 `%d`를 하나 가져야 한다.
    /// (플레이스홀더를 빠뜨린 번역은 런타임에 숫자가 사라진다.)
    func testFormatPlaceholdersSurviveTranslation() throws {
        let base = try stringsTable(for: Self.baseLanguage)
        for language in Self.translatedLanguages where language != Self.baseLanguage {
            let table = try stringsTable(for: language)
            for (key, baseValue) in base {
                let expected = baseValue.components(separatedBy: "%d").count - 1
                let actual = (table[key] ?? "").components(separatedBy: "%d").count - 1
                XCTAssertEqual(
                    actual, expected,
                    "\(language).lproj: \"\(key)\"의 %d 개수가 기준과 다르다"
                )
            }
        }
    }

    /// 앱이 실제로 쓰는 경로(`L10n`)가 런타임 언어와 무관하게 값을 돌려주는지.
    /// 조회에 실패하면 Foundation이 키를 그대로 돌려주므로, 그 상태를 잡아낸다.
    func testRuntimeLookupNeverFallsBackToRawKey() throws {
        let rendered: [(key: String, value: String)] = [
            ("menu.noAgents", L10n.Menu.noAgents),
            ("menu.quit", L10n.Menu.quit),
            ("menu.display", L10n.Menu.display),
            ("menu.clickAction", L10n.Menu.clickAction),
            ("display.summaryBadge", L10n.Display.summaryBadge),
            ("display.character", L10n.Display.character),
            ("click.none", L10n.Click.none),
            ("click.kaku", L10n.Click.kaku),
            ("status.idle", L10n.Status.idle),
            ("status.working", L10n.Status.working),
            ("status.blocked", L10n.Status.blocked),
            ("status.done", L10n.Status.done),
            ("status.unknown", L10n.Status.unknown),
            ("dashboard.disconnected", L10n.Dashboard.disconnected),
        ]
        for (key, value) in rendered {
            XCTAssertFalse(value.isEmpty, "\(key): 빈 문자열이 렌더링됐다")
            XCTAssertNotEqual(value, key, "\(key): 키가 그대로 노출됐다")
        }
        // 복수형은 키가 아니라 숫자가 들어갔는지로 확인한다.
        XCTAssertTrue(L10n.Dashboard.agents(7).contains("7"), "복수형에 숫자가 빠졌다")
    }

    // MARK: - 헬퍼

    private func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(
            L10n.resourceBundle.path(forResource: language, ofType: "lproj"),
            "\(language).lproj를 찾을 수 없다"
        )
        return try XCTUnwrap(Bundle(path: path))
    }

    private func stringsTable(for language: String) throws -> [String: String] {
        let path = try XCTUnwrap(
            L10n.resourceBundle.path(
                forResource: "Localizable", ofType: "strings", inDirectory: nil,
                forLocalization: language
            ),
            "\(language).lproj/Localizable.strings를 찾을 수 없다"
        )
        return try XCTUnwrap(
            NSDictionary(contentsOfFile: path) as? [String: String],
            "\(language).lproj/Localizable.strings 파싱 실패"
        )
    }

    private func keys(inStringsFileFor language: String) throws -> Set<String> {
        Set(try stringsTable(for: language).keys)
    }
}

private extension Bundle {
    func string(_ key: String) -> String {
        localizedString(forKey: key, value: "**MISSING**", table: nil)
    }

    func plural(_ key: String, _ count: Int) -> String {
        String(format: localizedString(forKey: key, value: "**MISSING**", table: nil), count)
    }
}
