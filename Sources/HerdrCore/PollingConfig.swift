import Foundation

/// 폴링 간격을 한 곳에서 조정한다 (#06 HITL에서 최종 확정 예정, 그 전까지 가정값).
public enum PollingConfig {
    /// 메뉴 열림 — 짧은 간격으로 신선하게.
    public static let openInterval: TimeInterval = 1.0
    /// 메뉴 닫힘 — 긴 간격으로 CPU/배터리 절약.
    public static let closedInterval: TimeInterval = 10.0
}
