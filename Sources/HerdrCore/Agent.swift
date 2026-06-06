import Foundation

/// herdr `agent list`가 반환하는 에이전트 상태.
/// 정의된 5개 값 외의 미지 값은 `.unknown`으로 안전하게 매핑한다.
public enum AgentStatus: String, Codable, Sendable {
    case idle
    case working
    case blocked
    case done
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AgentStatus(rawValue: raw) ?? .unknown
    }
}

/// `agent list` 응답의 단일 에이전트. 사용하는 필드만 디코딩하고 나머지는 무시한다.
public struct Agent: Codable, Sendable, Equatable {
    public let agent: String
    public let agentStatus: AgentStatus
    public let cwd: String
    public let paneId: String
    public let tabId: String
    public let workspaceId: String
    /// 사용자가 herdr UI에서 지금 보고 있는 pane이면 true.
    public let focused: Bool

    enum CodingKeys: String, CodingKey {
        case agent
        case agentStatus = "agent_status"
        case cwd
        case paneId = "pane_id"
        case tabId = "tab_id"
        case workspaceId = "workspace_id"
        case focused
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        agent = try c.decode(String.self, forKey: .agent)
        agentStatus = try c.decode(AgentStatus.self, forKey: .agentStatus)
        cwd = try c.decode(String.self, forKey: .cwd)
        paneId = try c.decode(String.self, forKey: .paneId)
        tabId = try c.decode(String.self, forKey: .tabId)
        workspaceId = try c.decode(String.self, forKey: .workspaceId)
        focused = try c.decodeIfPresent(Bool.self, forKey: .focused) ?? false
    }
}

/// `{"result":{"agents":[...],"type":"agent_list"}}` 구조 디코딩용.
struct AgentListResponse: Codable {
    struct Result: Codable {
        let agents: [Agent]
    }
    let result: Result
}

public enum AgentListDecoder {
    /// `agent list` 응답 JSON에서 에이전트 배열을 디코딩한다.
    public static func decode(_ data: Data) throws -> [Agent] {
        try JSONDecoder().decode(AgentListResponse.self, from: data).result.agents
    }
}
