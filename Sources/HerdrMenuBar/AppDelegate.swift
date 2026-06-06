import AppKit
import HerdrCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    // 기본은 표준 경로. 테스트 시 HERDR_BIN으로 덮어쓸 수 있다.
    private let herdrBinary = ProcessInfo.processInfo.environment["HERDR_BIN"] ?? "/opt/homebrew/bin/herdr"
    private lazy var client = AgentListClient(binaryPath: herdrBinary)
    private lazy var focusController = FocusController(herdrBinary: herdrBinary)
    private var timer: Timer?

    /// herdr를 실행 중인 kaku 앱 번들 id.
    private let kakuBundleId = "fun.tw93.kaku"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 없이 메뉴바에만 상주 (LSUIElement 동등)
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu.delegate = self
        menu.autoenablesItems = false   // enabled 상태를 직접 제어 (보기전용 항목도 정상색 유지)
        statusItem.menu = menu

        poll()                                  // #03: 실행 시 1회 폴링 후 렌더
        scheduleTimer(interval: PollingConfig.closedInterval)   // #04: 닫힘 간격으로 시작
    }

    // MARK: - Polling

    /// 한 틱: agent list 호출 → 집계 → 아이콘/드롭다운 갱신.
    /// 어떤 실패에서도 throw가 밖으로 새지 않아 크래시하지 않는다.
    private func poll() {
        let state: DashboardState
        do {
            state = .connected(try client.list())
        } catch {
            state = .disconnected   // 미실행/소켓/파싱 실패 — 다음 틱에 자동 재시도
        }
        render(state)
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
    }

    // MARK: - Render

    private func render(_ state: DashboardState) {
        guard let button = statusItem.button else { return }
        switch state {
        case .connected(let agents):
            MenuBarStyle.applyIcon(to: button, counts: StatusCounts(agents))
        case .disconnected:
            MenuBarStyle.applyDisconnected(to: button)
        }
        rebuildMenu(state)
    }

    private func rebuildMenu(_ state: DashboardState) {
        menu.removeAllItems()

        switch state {
        case .disconnected:
            menu.addItem(withTitle: DashboardRender.disconnectedMessage, action: nil, keyEquivalent: "")
        case .connected(let agents) where agents.isEmpty:
            menu.addItem(withTitle: "에이전트 없음", action: nil, keyEquivalent: "")
        case .connected(let agents):
            // 클릭 동작이 .none이면 항목은 비클릭(보기전용).
            let clickable = Settings.clickAction != .none
            let action = clickable ? #selector(focusAgent(_:)) : nil
            menu.addItem(MenuBarStyle.summaryItem(StatusCounts(agents)))
            menu.addItem(.separator())
            let groups = AgentGrouping.byWorkspace(agents)
            for (index, group) in groups.enumerated() {
                if index > 0 { menu.addItem(.separator()) }
                menu.addItem(MenuBarStyle.headerItem(group))
                for agent in group.agents {
                    menu.addItem(MenuBarStyle.agentItem(
                        agent, target: clickable ? self : nil, action: action
                    ))
                }
            }
        }

        menu.addItem(.separator())
        menu.addItem(clickActionSubmenuItem())
        menu.addItem(
            withTitle: "종료",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
    }

    /// "클릭 동작" 서브메뉴 — 현재 모드에 체크마크.
    private func clickActionSubmenuItem() -> NSMenuItem {
        let parent = NSMenuItem(title: "클릭 동작", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let current = Settings.clickAction
        for mode in ClickAction.allCases {
            let item = NSMenuItem(
                title: mode.label,
                action: #selector(selectClickAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (mode == current) ? .on : .off
            submenu.addItem(item)
        }
        parent.submenu = submenu
        return parent
    }

    @objc private func selectClickAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = ClickAction(rawValue: raw) else { return }
        Settings.clickAction = mode
        poll()   // 메뉴 즉시 재구성 (체크마크 + 항목 클릭성 갱신)
    }

    // MARK: - NSMenuDelegate (#04: 적응형 간격 전환)

    func menuWillOpen(_ menu: NSMenu) {
        poll()                                          // 열자마자 신선하게
        scheduleTimer(interval: PollingConfig.openInterval)
    }

    func menuDidClose(_ menu: NSMenu) {
        scheduleTimer(interval: PollingConfig.closedInterval)
    }

    // MARK: - 에이전트 클릭 → 패널로 이동 (검증된 3단계)

    @objc private func focusAgent(_ sender: NSMenuItem) {
        guard let paneId = sender.representedObject as? String else { return }
        switch Settings.clickAction {
        case .none:
            return
        case .kaku:
            // 1) kaku 앱을 OS 전면으로 (이게 없으면 herdr 내부 포커스만 바뀌고 화면은 안 따라옴)
            if let kaku = NSRunningApplication.runningApplications(withBundleIdentifier: kakuBundleId).first {
                kaku.activate(options: [.activateAllWindows])
            }
            // 2)·3) herdr 사는 kaku pane 활성화 + herdr agent focus
            focusController.focus(agentPaneId: paneId)
        }
    }
}
