# herdr 메뉴바 모니터

macOS 메뉴바에 상주하며 [herdr](https://herdr.dev)의 AI 코딩 에이전트(claude, codex 등) 상태를 한눈에 보여주는 네이티브 위젯. `herdr agent list`를 적응형으로 폴링해 지금 떠 있는 에이전트들의 상태(working/idle/blocked/done)를 메뉴바 아이콘과 드롭다운에 표시한다.

Swift + AppKit 기반. Dock 아이콘 없이 메뉴바에만 상주한다.

<img src="demo.png" alt="demo" width="280">


## 동작

- **메뉴바 아이콘** — 주의가 필요한 상태를 우선순위로 표시한다. blocked가 있으면 ⚠(빨강), 작업 중이면 ▶, 다 끝났으면 ✓, 전부 쉬면 ○. 0인 상태는 숨겨 폭을 아낀다.
- **드롭다운** — workspace별로 그룹핑해 에이전트를 나열한다. 각 줄은 색상 상태 점 + 에이전트 종류(claude/codex) + 상태 단어.
- **적응형 폴링** — 메뉴를 열면 1초, 닫으면 10초 간격으로 갱신해 idle CPU를 아낀다.
- **자동 복구** — herdr가 꺼져 있으면 회색 `—`로 "연결 안 됨"을 표시하고, 살아나면 자동으로 정상 화면으로 돌아온다. 어떤 실패에도 크래시하지 않는다.
- **클릭 → 패널 이동 (옵션)** — 드롭다운에서 에이전트를 클릭하면 해당 터미널 패널로 포커스를 옮긴다. 기본은 꺼져 있다(순수 보기전용).

## 요구 사항

- macOS 13 이상
- [Swift 6.1+](https://www.swift.org/install/macos/) (Xcode 또는 Swift toolchain)
- [herdr](https://herdr.dev) 설치 (기본 경로 `/opt/homebrew/bin/herdr`)

## 빌드

```bash
swift build
```

릴리스 빌드:

```bash
swift build -c release
```

## 실행

```bash
swift run
```

또는 빌드한 실행 파일을 직접:

```bash
.build/debug/HerdrMenuBar      # 또는 .build/release/HerdrMenuBar
```

실행하면 메뉴바 우측에 아이콘이 나타난다. 종료는 드롭다운의 **종료**(⌘Q).

> herdr 소켓은 기본 경로(`~/.config/herdr/herdr.sock`)를 자동 탐색하므로 별도 환경변수 설정이 필요 없다.

## .app 번들 만들기

배포·설치용 `.app` 번들을 만들려면:

```bash
scripts/build-app.sh
```

`dist/herdr-menu-bar.app`이 생성된다(릴리스 빌드 + Info.plist + ad-hoc 코드 서명 포함). 실행:

```bash
open dist/herdr-menu-bar.app
```

`/Applications`로 복사하면 일반 앱처럼 쓸 수 있다. 번들 식별자는 `dev.minung.herdr-menubar`.

> ad-hoc 서명이라 본인 Mac에서는 바로 실행되지만, 다른 사람에게 배포하려면 Developer ID 서명·공증(notarization)이 필요하다.

## 테스트

```bash
swift test
```

로직(파싱·집계·그룹핑·우선순위·복구)은 `HerdrCore`에 분리해 단위 테스트로 검증한다. herdr가 실행 중이면 라이브 스모크 테스트도 함께 돌고, 없으면 자동으로 skip된다.

## 설정

클릭 동작은 드롭다운의 **클릭 동작** 서브메뉴에서 선택한다(`이동 안 함` / `kaku로 이동`). 설정은 macOS `UserDefaults`에 저장된다 — `.app` 번들로 실행하면 `dev.minung.herdr-menubar` 도메인, `swift run`으로 실행하면 `HerdrMenuBar` 도메인을 쓴다.

## 구조

```
Sources/
  HerdrCore/        # 플랫폼 중립 로직 (CLI 셸아웃, 디코딩, 집계, 우선순위)
  HerdrMenuBar/     # AppKit UI (NSStatusItem, 메뉴, 스타일, 설정)
Tests/
  HerdrCoreTests/   # 단위 테스트 + 실제 응답 픽스처
```

## 다운로드 (사용자)

[Releases](../../releases)에서 최신 `herdr-menu-bar-x.y.z.zip`을 받아 압축을 푼다.

`herdr-menu-bar.app`을 `/Applications`로 옮긴 뒤, **최초 1회는 우클릭 → 열기**로 실행한다(그 다음부터는 그냥 더블클릭).

> ⚠️ 처음 더블클릭하면 "확인되지 않은 개발자" 경고가 뜬다. 이 앱은 ad-hoc 서명만 돼 있어서다(Apple 공증 없음). **우클릭 → 열기 → 열기**를 한 번 누르면 이후로는 정상 실행된다.

## 릴리스 만들기 (메인테이너)

```bash
scripts/package-release.sh          # Info.plist의 버전 사용
scripts/package-release.sh 0.2.0    # 버전 명시
```

`dist/herdr-menu-bar-<버전>.zip`이 생성된다. 이 zip을 [GitHub Releases](../../releases) 새 릴리스에 끌어다 업로드하면 끝(자동화·CI 불필요).

> 버전을 올리려면 `Resources/Info.plist`의 `CFBundleShortVersionString`을 수정한다.

## 한계

- 클릭 → 패널 이동의 `kaku로 이동` 모드는 [kaku](https://github.com/tw93/Kaku) 터미널 안에서 herdr를 단일 pane으로 쓰는 환경을 가정한다. 다른 GUI 터미널은 아직 지원하지 않는다.
