import Foundation

/// 메뉴바 상태 항목에 에이전트를 표시하는 방식.
public enum MenuBarDisplayMode: String, CaseIterable, Sendable {
    /// 기존 상태 집계 배지.
    case summaryBadge
    /// 상태별 캐릭터 표시.
    case character

    /// 메뉴에 표시할 사람용 라벨.
    public var label: String {
        switch self {
        case .summaryBadge: return UILanguage.current == .ko ? "요약 배지" : "Summary badge"
        case .character: return UILanguage.current == .ko ? "캐릭터" : "Character"
        }
    }
}
