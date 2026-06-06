# herdr menubar

A menu-bar app that shows, at a glance, the status of AI agents running in [herdr](https://herdr.dev).

<img src="demo.png" alt="demo" width="280">

> 🇰🇷 [한국어 README](README.KO.md)

## Download

Grab the latest `.dmg` or `.zip` from [Releases](../../releases), then move `herdr-menu-bar.app` to `/Applications`.

The first launch needs **right-click → Open** (the app is ad-hoc signed, not notarized, so macOS warns once). After that, double-click works.

**Requires** macOS 13+ and [herdr](https://herdr.dev) (default path `/opt/homebrew/bin/herdr`, override with the `HERDR_BIN` environment variable). The socket is auto-discovered.

## Features

- **Menu-bar icon** — highest-priority state at a glance: ⚠ blocked, ▶ working, ✓ done, ○ idle.
- **Dropdown** — agents grouped by workspace, each with a status dot, kind (claude/codex), and state.
- **Adaptive polling** — 1s while open, 10s while closed.
- **Self-healing** — shows `—` when herdr is down, recovers automatically, never crashes.
- **Click → focus pane** — optional, off by default. Clicking an agent focuses its terminal pane.

## Build

Requires [Swift 6.1+](https://www.swift.org/install/macos/).

```bash
swift build              # or: swift build -c release
swift run                # run directly
swift test               # run tests
scripts/build-app.sh     # produce dist/herdr-menu-bar.app
```

## Configuration

Click behavior is set in the **클릭 동작** (Click action) dropdown submenu — `이동 안 함` (do nothing) or `kaku로 이동` (focus in kaku). Settings persist in `UserDefaults`.

## Layout

```
Sources/HerdrCore/      platform-neutral logic (CLI, decoding, aggregation)
Sources/HerdrMenuBar/   AppKit UI (NSStatusItem, menu, settings)
Tests/HerdrCoreTests/   unit tests + fixtures
```

## Releasing (maintainers)

```bash
scripts/package-release.sh   # .zip
scripts/package-dmg.sh       # .dmg
```

Drag the artifact from `dist/` onto a new [GitHub Release](../../releases). Use [`.github/RELEASE_TEMPLATE.md`](.github/RELEASE_TEMPLATE.md) for the notes, and bump `CFBundleShortVersionString` in `Resources/Info.plist`.

## Limitations

- `kaku로 이동` requires the [kaku](https://github.com/tw93/Kaku) CLI on `PATH` and matches the pane whose title is `herdr`. Other terminals aren't supported yet.

## Contributing

Issues and PRs welcome. Run `swift test` before opening a PR, and keep changes surgical.
