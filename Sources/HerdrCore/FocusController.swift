import Foundation

/// `kaku cli list --format json`의 pane 항목 (필요한 필드만).
struct KakuPane: Decodable {
    let paneId: Int
    let title: String

    enum CodingKeys: String, CodingKey {
        case paneId = "pane_id"
        case title
    }
}

public enum KakuPaneFinder {
    /// kaku list JSON에서 herdr가 사는 pane id를 찾는다.
    /// herdr는 자기 pane 타이틀을 `herdr`로 세팅하므로 title 매칭으로 식별.
    /// 매칭이 없거나 파싱 실패면 nil.
    public static func herdrPaneId(fromKakuListJSON data: Data) -> Int? {
        guard let panes = try? JSONDecoder().decode([KakuPane].self, from: data) else {
            return nil
        }
        return panes.first(where: { $0.title == "herdr" })?.paneId
    }
}

/// 에이전트 클릭 → 그 패널로 이동. 검증된 3단계 흐름:
/// 1) (호출자가) kaku 앱 전면화  2) herdr 사는 kaku pane 활성화  3) herdr agent focus.
///
/// 이 컨트롤러는 2)·3)의 shell out을 담당한다. 1)은 AppKit 의존이라 앱 레이어에서.
/// 어떤 단계가 실패해도 throw하지 않고 best-effort로 진행한다(UI 크래시 방지).
public struct FocusController {
    private let herdrBinary: String
    private let kakuBinary: String
    private let runner: ProcessRunner

    public init(
        herdrBinary: String = "/opt/homebrew/bin/herdr",
        kakuBinary: String = "kaku",
        runner: ProcessRunner = .init()
    ) {
        self.herdrBinary = herdrBinary
        self.kakuBinary = kakuBinary
        self.runner = runner
    }

    /// 주어진 에이전트 pane으로 포커스를 옮긴다 (kaku pane 활성화 + herdr focus).
    /// 실패는 무시(best-effort).
    public func focus(agentPaneId: String) {
        // 2) herdr가 사는 kaku pane을 찾아 활성화
        if let listData = try? runner.run(kakuBinary, ["cli", "list", "--format", "json"]),
           let kakuPane = KakuPaneFinder.herdrPaneId(fromKakuListJSON: listData) {
            _ = try? runner.run(kakuBinary, ["cli", "activate-pane", "--pane-id", "\(kakuPane)"])
        }
        // 3) herdr 안에서 해당 에이전트로 포커스
        _ = try? runner.run(herdrBinary, ["agent", "focus", agentPaneId])
    }
}
