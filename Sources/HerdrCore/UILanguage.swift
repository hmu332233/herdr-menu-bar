import Foundation

/// UI language for user-facing strings. English is the default; the original
/// Korean is used when the system's preferred language is Korean.
///
/// Kept in code (rather than .lproj resource bundles) so the bare-binary
/// packaging in `scripts/build-app.sh` needs no resource-bundle plumbing,
/// and tests can pass a language explicitly instead of depending on the
/// host machine's locale.
public enum UILanguage: String, CaseIterable, Sendable {
    case en
    case ko

    /// Resolved from the user's preferred languages.
    public static var current: UILanguage {
        Locale.preferredLanguages.first?.hasPrefix("ko") == true ? .ko : .en
    }
}

/// Fixed menu strings used by the AppKit layer.
public enum MenuText {
    public static var noAgents: String {
        UILanguage.current == .ko ? "에이전트 없음" : "No agents"
    }
    public static var quit: String {
        UILanguage.current == .ko ? "종료" : "Quit"
    }
    public static var menuBarDisplay: String {
        UILanguage.current == .ko ? "메뉴바 표시" : "Menu bar display"
    }
    public static var clickAction: String {
        UILanguage.current == .ko ? "클릭 동작" : "Click action"
    }
}
