import Foundation

/// 사용자에게 보이는 모든 문자열의 단일 진입점.
///
/// 번역은 `Sources/HerdrCore/Resources/<language>.lproj/Localizable.strings`에 있고,
/// 복수형은 `Localizable.stringsdict`가 담당한다. 언어를 추가하려면 `.lproj`
/// 디렉터리 하나만 만들면 된다 — Swift 코드는 건드릴 필요가 없다.
///
/// 표시 언어는 macOS 시스템 언어 설정을 따른다. 번역이 없는 언어는
/// `Package.swift`의 `defaultLocalization`(= `en`)으로 폴백한다.
public enum L10n {
    /// 메뉴 구조 텍스트.
    public enum Menu {
        public static var noAgents: String { t("menu.noAgents") }
        public static var quit: String { t("menu.quit") }
        public static var display: String { t("menu.display") }
        public static var clickAction: String { t("menu.clickAction") }
    }

    /// 메뉴바 표시 방식 라벨.
    public enum Display {
        public static var summaryBadge: String { t("display.summaryBadge") }
        public static var character: String { t("display.character") }
    }

    /// 클릭 동작 라벨.
    public enum Click {
        public static var none: String { t("click.none") }
        public static var kaku: String { t("click.kaku") }
    }

    /// 에이전트 상태 단어.
    public enum Status {
        public static var idle: String { t("status.idle") }
        public static var working: String { t("status.working") }
        public static var blocked: String { t("status.blocked") }
        public static var done: String { t("status.done") }
        public static var unknown: String { t("status.unknown") }
    }

    /// 드롭다운 요약/상태 문구.
    public enum Dashboard {
        public static var disconnected: String { t("dashboard.disconnected") }

        /// 총 에이전트 수. 복수형 규칙은 `.stringsdict`가 언어별로 처리한다.
        public static func agents(_ count: Int) -> String { f("dashboard.agents", count) }

        public static func working(_ count: Int) -> String { f("dashboard.count.working", count) }
        public static func blocked(_ count: Int) -> String { f("dashboard.count.blocked", count) }
        public static func done(_ count: Int) -> String { f("dashboard.count.done", count) }
        public static func idle(_ count: Int) -> String { f("dashboard.count.idle", count) }
    }

    // MARK: - 내부

    /// 번역 리소스가 담긴 번들. 테스트에서 언어별 `.lproj`를 직접 열 때 쓴다.
    static var resourceBundle: Bundle { .module }

    private static func t(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }

    /// `%d` 치환 + `.stringsdict` 복수형 토큰(`%#@…@`) 해석.
    private static func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }
}
