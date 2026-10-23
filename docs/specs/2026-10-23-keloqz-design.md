# Keloqz — design spec

Date: 2026-10-23
Status: approved in brainstorming, awaiting spec review

## 1. Goal

A small pixel-art German Shepherd named **Keloqz** that floats above every window on the Mac
(like the Codex mascot), shows the live status of **all** running Claude Code sessions, and
delivers the **Lomo-Saltado** "¡Saltado!" turn-finished notifications itself. It replaces the
old MasIAPet app (`Mas-IA/pet-app`), which followed a single project and sat at desktop-icon level.

Success looks like:

- With 2+ Claude Code sessions open, Keloqz shows how many are cooking, what the most recent one
  is doing, and lists all of them on click.
- When a session finishes a turn, Keloqz jumps and shows a "¡Saltado!" bubble, and **no** macOS
  banner appears.
- When Keloqz is not running, Lomo-Saltado's macOS banners come back on their own.
- Clicking a session in the list brings its Terminal.app tab to the front.

## 2. Decisions made

| Topic | Decision |
|---|---|
| Notifications | Keloqz replaces macOS banners **only while it is running** (heartbeat hand-off). |
| Window level | Always on top, draggable anywhere, all Spaces, full-screen apps too. |
| Interaction | Codex style: status bubble, badge, hover toolbar, click → session list. |
| Art | Pixel German Shepherd, Codex-like rendering (rim-lit top edges, soft warm glow), dark-sable coat from the user's reference photo, rounded ears (right one folded in idle), red polka-dot bandana. |
| Poses | `idle`, `play` (ball, = working), `done` (jump), `sleep` (lying on the floor). |
| Approach | Native Swift app; sprites pre-rendered to PNG from the approved JS drawing code. |
| UI language | Spanish (matches Lomo-Saltado). |
| Old app | MasIAPet is retired (process, hooks, `~/.masia-pet/`). |

Approved art reference: `PRJ_P/.superpowers/brainstorm/23408-1792781830/content/keloqz-v9.html`.

## 3. Out of scope (v1)

- Voice input (the Codex mic button).
- "Needs permission" alerts — Lomo-Saltado exposes no permission event.
- Linux / Windows.
- Terminals other than Terminal.app for tab focusing (others fall back to activating the app).

## 4. Architecture

Project: `PRJ_P/keloqz/` (own git repo).

```
keloqz/
  art/keloqz.js              approved drawing code (pure functions: pose, frame → pixel buffer)
  art/preview.html           browser preview that imports keloqz.js, for future art tweaks
  tools/render-sprites.mjs   Node script: keloqz.js → PNG sprite sheets
  Sources/Keloqz/
    KeloqzApp.swift          entry; accessory activation policy (no Dock, no Cmd+Tab)
    PetPanel.swift           floating NSPanel, drag handling, saved position, screen clamping
    SpritePlayer.swift       plays a pose's frames at its frame rate
    PoseChooser.swift        pure: (sessions, pending notification, idle time) → pose
    SessionStore.swift       reads + merges session sources → [Session]
    Notifier.swift           pure diffing: old [Session] vs new → [TurnFinished]
    Heartbeat.swift          writes ~/.claude/saltado/keloqz.json
    TerminalFocus.swift      pid → tty → AppleScript to select the Terminal tab
    NewSession.swift         opens a Terminal tab running `cd <dir> && claude`
    Views/Bubble.swift, Views/SessionList.swift, Views/Toolbar.swift, Views/Badge.swift
    Resources/sprites/*.png  generated, committed
  Tests/KeloqzTests/         unit tests + JSON fixtures
  scripts/build.sh           SwiftPM build → Keloqz.app (ad-hoc signed); --install → /Applications
  docs/specs/                this file
```

Build constraints (same as MasIAPet and the Coucou fork): no Xcode, only Command Line Tools. Build
with `SDKROOT=…/MacOSX26.5.sdk swift build -c release --build-system native` (the 27 SDK lacks
the SwiftUI macro plugin). `build.sh` assembles the `.app` bundle (Info.plist with
`LSUIElement`, sprites, icon), ad-hoc signs it, and fails if any sprite sheet is missing.

### Unit boundaries

- **SessionStore** only reads files and publishes `[Session]`. No UI knowledge.
- **Notifier** and **PoseChooser** are pure functions over values; the easiest units to test.
- **SpritePlayer** only plays a named pose; it never decides which one.
- **The Swift side never draws the dog.** All pixels come from `render-sprites.mjs`.

## 5. Sprites

- `art/keloqz.js` is the mockup's drawing code moved into a module: palette, primitives
  (`rect`, `ell`, `tri`, `stroke`), the outline pass (near-black outline on transparent
  neighbours, shadow excluded) and the rim-light pass (+25 % toward white on top edges).
- Grid: 48 px tall. `idle` and `done` are 48 wide; `play` and `sleep` are 64 wide.
- Frames are the full loops of the approved mockup, so the player just loops a strip:

  | Pose | Frames | FPS | Why that count |
  |---|---|---|---|
  | `idle` | 154 | ~2 | tail wag (2) × blink (every 7th) × ear twitch (every 11th) = LCM 154 |
  | `play` | 8 | ~6 | one ball bounce + swat |
  | `done` | 2 | ~2 | jump up / down |
  | `sleep` | 6 | ~2 | breathing (2) × rising Z's (3 steps of 2) |
- Output: one horizontal strip per pose at 1×, `Resources/sprites/<pose>.png`, plus
  `sprites.json` with `{pose: {frames, width, height, fps}}`. The app scales with
  nearest-neighbour (2×/3×/4×) and adds the warm glow as a soft shadow.
- `render-sprites.mjs` uses only Node built-ins (pixel buffer → PNG via `zlib`).

## 6. Data flow

### 6.1 Session sources

1. `~/.claude/sessions/<pid>.json` (written by Claude Code): `pid`, `sessionId`, `cwd`, `name`,
   `status` (`busy`/`idle`), `updatedAt`.
2. `~/.claude/saltado/cocina/<sessionId>.json` (written by Lomo-Saltado every 15 s and on
   change): `name`, `cwd`, `phase` (`cooking`/`cooked`), `dish`, `activity`, `startedAt`,
   `endedAt`, `ops`, `errors`.

### 6.2 SessionStore

- Watches both directories with FSEvents; a 3 s timer re-reads as a fallback.
- Joins on `sessionId`. Field precedence: name from cocina (renamable with `/saltado nombre`),
  else from sessions; status from cocina `phase` when present, else sessions `status`.
- Drops any session whose `pid` is dead (`kill(pid, 0)` fails), and cocina files with no live
  matching session.
- Sessions without a cocina file (e.g. desktop app) appear with busy/idle only.
- Unreadable or half-written JSON: skip that file this read; retry next read.

```swift
struct Session: Equatable {
  let id: String          // sessionId
  let pid: Int32
  let name: String
  let cwd: String
  var isCooking: Bool
  var dish: String?       // the prompt
  var activity: String?   // current step
  var startedAt: Date?
  var endedAt: Date?
  var ops: Int
  var errors: Int
}
```

### 6.3 Notifier

- The first read after launch is a **baseline** and emits nothing.
- A `TurnFinished` is emitted when a session goes from cooking to not cooking, or its `endedAt`
  changes to a newer value.
- `TurnFinished`: name, dish (truncated to ~60 chars), duration (`endedAt − startedAt`),
  `ok = errors == 0`, `sticky = duration > 120 s`.
- Events go into a FIFO queue; the bubble shows them one at a time.

### 6.4 Heartbeat and hand-off with Lomo-Saltado

- Keloqz writes `~/.claude/saltado/keloqz.json` every 10 s, atomically:
  `{"pid": <int>, "updatedAt": <epoch ms>, "muted": <bool>}`. It deletes the file on quit.
- Lomo-Saltado change (`saltado/hooks/register.tsx`, `notify`): before sending a banner, read
  `keloqz.json`. **Skip the banner** if `now − updatedAt < 30 000` and the pid is alive.
  Otherwise behave exactly as today. Muted counts as "Keloqz handles it", so banners are skipped
  too.
- Failure direction is safe: a missing or stale file means banners come back. A failure can
  only cause duplicate notifications, never missed ones.
- The change lands in `mbaudran/Lomo-Saltado-Claude-mod`: clone into `PRJ_P/`, commit with a
  test, **push only after the user confirms**, then update the marketplace copy at
  `~/.claude/plugins/marketplaces/lomo-saltado`.

## 7. UI behaviour

### 7.1 Panel

- Borderless, non-activating `NSPanel`, level `.floating`, collection behaviour
  `canJoinAllSpaces + fullScreenAuxiliary + ignoresCycle`, transparent background.
- Drag anywhere (a click is told apart from a drag at 3 pt of movement, as in MasIAPet).
- Position saved in `UserDefaults`. On launch or screen change, clamp it back onto a visible
  screen. First launch: bottom-right of the main screen.
- Size: 48 px grid at **2×** by default (~96 pt). Right-click → Tamaño S/M/L = 2×/3×/4×.

### 7.2 Bubble (Codex pill: frosted, rounded, white text; above the dog)

Priority, one at a time:

1. Pending notification: **"<name> — ¡Saltado! ✅"** (❌ on errors), subtitle
   "<dish> · <duration>". Non-sticky hides after 6 s; sticky stays until clicked.
2. Else the most recently active cooking session: **"<name> — <dish>"**, subtitle
   "▸ <activity> · <N> 🍳".
3. Else no bubble; on hover a small "<N> sesiones · todo servido".

When a notification arrives: `done` pose, the "Ping" system sound (unless muted), and a red dot
on the dog until the bubble is seen.

### 7.3 Badge

A small number on the dog's shoulder: count of cooking sessions. Hidden at 0.

### 7.4 Toolbar (appears on hover, under the dog)

- 🐾 opens the session list.
- ＋ shows a menu of the 5 most recent distinct project folders (from session `cwd`s) plus
  "Otra carpeta…" (`NSOpenPanel`), then opens a new Terminal tab running `cd <dir> && claude`.
- 🔕 toggles mute (also in the right-click menu). Muted: no bubbles, no sound, heartbeat says
  `muted: true`. Badge and list keep working.

### 7.5 Session list (click the dog or 🐾)

A frosted card next to the dog, one row per session, cooking sessions first, then most recently
finished:

```
● PRJ_P            cocinando · 3m 12s   14 ops
  ▸ Escribiendo la spec de Keloqz
✓ chaska-nawi      servido hace 4m ✅
  close the server
○ api              en espera
```

Clicking a row calls `TerminalFocus` for that pid: find its tty (`ps -o tty= -p <pid>`), then
use AppleScript to select the Terminal.app tab with that tty and raise its window. If there is
no tty or no matching tab, activate Claude.app when it is a desktop-app session, else activate
Terminal. The first use triggers macOS's Automation prompt (Keloqz → Terminal). Click outside or
press Esc to close the list.

### 7.6 Poses (PoseChooser)

| Condition (first match wins) | Pose |
|---|---|
| A notification was shown in the last 2 s | `done` |
| Any session cooking | `play` |
| No cooking and no hover/click for 5 min | `sleep` |
| Otherwise | `idle` |

Hover or click while asleep → `idle`.

### 7.7 Right-click menu

Silenciar · Tamaño ▸ (S/M/L) · Abrir al iniciar sesión (✓ by default, via
`SMAppService.mainApp`) · Salir de Keloqz.

## 8. Error handling

| Failure | Behaviour |
|---|---|
| A session JSON is missing, partial or invalid | Skip it this read; retry next read. |
| `cocina/` missing (mod not installed) | Run on `sessions/` only (busy/idle). |
| Terminal tab not found / Automation denied | Activate Terminal (or Claude.app). |
| Heartbeat write fails | Mod sees it as stale → macOS banners return (safe direction). |
| Login-item registration fails | Menu item stays unchecked; nothing else is affected. |
| Panel ends up off-screen (monitor removed) | Clamp to the nearest visible screen. |

## 9. Testing

- **Swift unit tests (`swift test`)** with JSON fixtures:
  - SessionStore merging both sources, precedence rules, dead-pid filtering, invalid JSON
    skipped.
  - Notifier: launch baseline, cooking→cooked, `endedAt` change, ✅ vs ❌, sticky at >120 s,
    FIFO queue.
  - PoseChooser: every row of the table in §7.6.
  - Heartbeat: written fields, atomic write, removal on quit.
- **Lomo-Saltado:** a test in `saltado/tests/saltado.test.ts` covering fresh heartbeat → no
  banner, stale → banner, missing → banner, dead pid → banner, muted → no banner.
- **Sprites:** a Node test decodes the generated PNGs and checks them against the pixel buffers
  from `keloqz.js` (catches encoding, scale and palette mistakes), plus the frame counts and
  sizes in `sprites.json`.
- **Manual acceptance (before calling it done):** with 2 real sessions, check the badge count,
  the play pose while cooking, a ¡Saltado! bubble with no macOS banner, that clicking a row
  focuses the right tab, and that banners return after quitting Keloqz.

## 10. Retiring MasIAPet

Each step is confirmed with the user before it runs:

1. Stop the running `MasIAPet` process.
2. Remove the three `~/.masia-pet/status.json` hooks from `Mas-IA/.claude/settings.json`.
3. Delete `~/.masia-pet/`.
4. Leave `Mas-IA/pet-app/` source in place unless the user asks to delete it.

There is no LaunchAgent to remove.
