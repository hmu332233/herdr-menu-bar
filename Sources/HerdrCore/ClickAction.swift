import Foundation

/// 드롭다운에서 에이전트를 클릭했을 때의 동작.
/// 터미널 환경마다 다르므로 사용자가 선택한다. 기본은 보기전용(`none`).
public enum ClickAction: String, CaseIterable, Sendable {
    /// 아무것도 안 함 (순수 보기전용).
    case none
    /// kaku로 전환 + herdr agent focus (kaku 안에서 herdr를 쓸 때).
    case kaku

    /// 메뉴에 표시할 사람용 라벨.
    public var label: String {
        switch self {
        case .none: return L10n.Click.none
        case .kaku: return L10n.Click.kaku
        }
    }
}
