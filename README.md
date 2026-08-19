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

Click behavior is set in the **Click action** dropdown submenu — `Do nothing` or `Focus in kaku`. Settings persist in `UserDefaults`.

## Localization

The UI ships in **English** (default) and **Korean**, and follows your macOS system language. Unsupported languages fall back to English.

All user-facing strings live in `Sources/HerdrCore/Resources/<language>.lproj/`. Adding a language needs no Swift changes:

```bash
cp -R Sources/HerdrCore/Resources/en.lproj Sources/HerdrCore/Resources/ja.lproj
# translate the values in ja.lproj/Localizable.strings and Localizable.stringsdict
swift test   # verifies your new file covers every key
```

Then add the language code to `translatedLanguages` in `Tests/HerdrCoreTests/LocalizationTests.swift`. The test suite fails on a missing key, an empty value, or a dropped `%d` placeholder, so an incomplete translation cannot ship silently.

Plural rules live in `Localizable.stringsdict` — English distinguishes `1 agent` from `2 agents`, Korean uses one form. Languages with more plural categories (Russian, Arabic, Polish) can declare `few`, `many`, and `zero` there.

## Layout

```
Sources/HerdrCore/      platform-neutral logic (CLI, decoding, aggregation)
Sources/HerdrCore/Resources/<lang>.lproj/   translations (strings + plurals)
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

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/hmu332233"><img src="https://github.com/hmu332233.png?s=100" width="100px;" alt="hmu332233"/><br /><sub><b>hmu332233</b></sub></a><br /><a href="https://github.com/hmu332233/herdr-menu-bar/commits?author=hmu332233" title="Code">💻</a> <a href="#maintenance-hmu332233" title="Maintenance">🚧</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/simulieren"><img src="https://avatars.githubusercontent.com/u/8380383?v=4?s=100" width="100px;" alt="simulieren"/><br /><sub><b>simulieren</b></sub></a><br /><a href="#translation-simulieren" title="Translation">🌍</a> <a href="https://github.com/hmu332233/herdr-menu-bar/commits?author=simulieren" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
