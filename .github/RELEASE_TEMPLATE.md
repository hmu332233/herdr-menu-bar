<!--
GitHub Release description template.
When drafting a new release, copy this content and fill in the version & changes.
Attach: herdr-menu-bar-<version>.dmg, herdr-menu-bar-<version>.zip
-->

A macOS menu bar widget that shows your herdr AI agents (claude, codex, …) at a glance.

## Install

Grab whichever you prefer:

- **`herdr-menu-bar-x.y.z.dmg`** — open it and drag `herdr-menu-bar.app` into `Applications`.
- **`herdr-menu-bar-x.y.z.zip`** — unzip and move `herdr-menu-bar.app` to `/Applications`.

### ⚠️ First launch (important)

This app is **not notarized by Apple**, so the first time you double-click it you'll see an *"unidentified developer"* warning. Do one of the following once, and it will open normally afterward:

- **Right-click `herdr-menu-bar.app` → Open → Open**, or
- Go to *System Settings → Privacy & Security* and click **"Open Anyway"**.

Once running, the icon appears on the right side of the menu bar. Quit via **Quit** (⌘Q) in the dropdown.

## Requirements

- macOS 13 or later
- [herdr](https://herdr.dev) installed (the app polls `herdr agent list`)

## What's changed

<!-- For the first release use the line below; afterward list only that version's changes. -->
- First release — menu bar status, per-workspace dropdown, adaptive polling, herdr auto-recovery, click-to-focus a pane (optional).

---

For building from source and detailed usage, see the [README](../../#readme).
