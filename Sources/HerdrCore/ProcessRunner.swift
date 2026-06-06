import Foundation

public enum ProcessError: Error, Equatable {
    /// 프로세스를 띄우지 못함 (바이너리 부재 등).
    case launchFailed(String)
    /// 프로세스가 0이 아닌 코드로 종료.
    case nonZeroExit(code: Int32, stderr: String)
}

/// 외부 바이너리를 shell out 해 stdout을 캡처한다.
/// 바이너리 이름만 주면 PATH에서 찾고, 절대경로면 그대로 실행한다.
public struct ProcessRunner {
    public init() {}

    public func run(_ binary: String, _ arguments: [String]) throws -> Data {
        let process = Process()
        if binary.hasPrefix("/") {
            process.executableURL = URL(fileURLWithPath: binary)
            process.arguments = arguments
        } else {
            // PATH 탐색을 위해 /usr/bin/env 경유.
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [binary] + arguments
        }

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw ProcessError.launchFailed(error.localizedDescription)
        }

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ProcessError.nonZeroExit(
                code: process.terminationStatus,
                stderr: String(data: errData, encoding: .utf8) ?? ""
            )
        }
        return outData
    }
}
