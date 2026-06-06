import Foundation
import HerdrCore

/// UserDefaults에 영속되는 앱 설정.
enum Settings {
    private static let clickActionKey = "clickAction"

    /// 에이전트 클릭 동작. 기본 `.none`(보기전용).
    static var clickAction: ClickAction {
        get {
            guard let raw = UserDefaults.standard.string(forKey: clickActionKey),
                  let action = ClickAction(rawValue: raw) else {
                return .none
            }
            return action
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: clickActionKey)
        }
    }
}
