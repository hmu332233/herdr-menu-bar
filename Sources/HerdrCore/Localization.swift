import Foundation

/// 앱 UI에 사용할 언어. `system`은 macOS 언어 설정을 그대로 따른다.
public enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case english = "en"
    case korean = "ko"

    /// 언어 메뉴에서는 각 언어가 어떤 UI 언어에서도 알아보기 쉽도록 자칭을 쓴다.
    public var label: String {
        switch self {
        case .system: return L10n.Language.system
        case .english: return "English"
        case .korean: return "한국어"
        }
    }

    fileprivate var localizationCode: String? {
        self == .system ? nil : rawValue
    }
}

/// 사용자에게 보이는 모든 문자열의 단일 진입점.
///
/// 번역은 `Sources/HerdrCore/Resources/<language>.lproj/Localizable.strings`에 있고,
/// 복수형은 `Localizable.stringsdict`가 담당한다.
///
/// 기본은 macOS 시스템 언어 설정을 따르며, 사용자가 앱 안에서 영어/한국어로
/// 덮어쓸 수 있다. 번역이 없는 언어는 `Package.swift`의
/// `defaultLocalization`(= `en`)으로 폴백한다.
public enum L10n {
    static let languagePreferenceKey = "appLanguage"
    private static let supportedLocalizationCodes = [
        AppLanguage.english.rawValue,
        AppLanguage.korean.rawValue,
    ]

    /// 현재 언어 선택. 시스템 설정은 override를 저장하지 않는다.
    public static var language: AppLanguage {
        get {
            guard let raw = UserDefaults.standard.string(forKey: languagePreferenceKey),
                  let language = AppLanguage(rawValue: raw) else {
                return .system
            }
            return language
        }
        set {
            if newValue == .system {
                UserDefaults.standard.removeObject(forKey: languagePreferenceKey)
            } else {
                UserDefaults.standard.set(newValue.rawValue, forKey: languagePreferenceKey)
            }
        }
    }

    /// 메뉴 구조 텍스트.
    public enum Menu {
        public static var noAgents: String { t("menu.noAgents") }
        public static var quit: String { t("menu.quit") }
        public static var language: String { t("menu.language") }
        public static var clickAction: String { t("menu.clickAction") }
    }

    /// 언어 선택 메뉴 라벨.
    public enum Language {
        public static var system: String { t("language.system") }
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

    /// 배포 앱에서는 표준 Resources 위치를, 개발·테스트에서는 SwiftPM 번들을 쓴다.
    static var resourceBundle: Bundle {
        if let url = Bundle.main.resourceURL?
            .appendingPathComponent("HerdrMenuBar_HerdrCore.bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return .module
    }

    static func bundle(for language: AppLanguage) -> Bundle {
        let resolvedLanguage = language == .system ? systemLanguage() : language
        guard let code = resolvedLanguage.localizationCode,
              let path = resourceBundle.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return resourceBundle
        }
        return bundle
    }

    static func systemLanguage(for preferences: [String] = Locale.preferredLanguages) -> AppLanguage {
        let code = Bundle.preferredLocalizations(
            from: supportedLocalizationCodes,
            forPreferences: preferences
        ).first ?? AppLanguage.english.rawValue
        return AppLanguage(rawValue: code) ?? .english
    }

    private static func t(_ key: String) -> String {
        bundle(for: language).localizedString(forKey: key, value: nil, table: nil)
    }

    /// `%d` 치환 + `.stringsdict` 복수형 토큰(`%#@…@`) 해석.
    private static func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }
}
