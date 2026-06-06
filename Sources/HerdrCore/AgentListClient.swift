import Foundation

public enum AgentListError: Error, Equatable {
    /// 프로세스를 띄우지 못함 (바이너리 부재 등).
    case launchFailed(String)
    /// 프로세스가 0이 아닌 코드로 종료 (herdr 미실행/소켓 연결 실패 등).
    case nonZeroExit(code: Int32, stderr: String)
    /// JSON 디코딩 실패.
    case decodeFailed(String)
}

/// `herdr agent list`를 shell out 해 구조화된 에이전트 배열을 얻는다.
///
/// 소켓 경로 환경변수 주입은 불필요하다 — CLI가 기본 경로
/// (`~/.config/herdr/herdr.sock`)를 자동 탐색한다. GUI 앱에도 `HOME`은
/// 정상 존재하므로 별도 환경변수 없이 동작한다.
public struct AgentListClient {
    private let binaryPath: String
    private let runner: ProcessRunner

    public init(binaryPath: String = "/opt/homebrew/bin/herdr", runner: ProcessRunner = .init()) {
        self.binaryPath = binaryPath
        self.runner = runner
    }

    /// `herdr agent list`를 실행하고 stdout을 그대로 반환한다.
    /// 실패는 `AgentListError`로 throw 한다.
    public func runRaw() throws -> Data {
        do {
            return try runner.run(binaryPath, ["agent", "list"])
        } catch let ProcessError.launchFailed(message) {
            throw AgentListError.launchFailed(message)
        } catch let ProcessError.nonZeroExit(code, stderr) {
            throw AgentListError.nonZeroExit(code: code, stderr: stderr)
        }
    }

    /// `herdr agent list`를 실행하고 디코딩된 에이전트 배열을 반환한다.
    public func list() throws -> [Agent] {
        let data = try runRaw()
        do {
            return try AgentListDecoder.decode(data)
        } catch {
            throw AgentListError.decodeFailed(error.localizedDescription)
        }
    }
}
