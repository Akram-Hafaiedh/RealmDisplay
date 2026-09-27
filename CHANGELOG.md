# Changelog

## 0.2.0 — 2026-09-27

Chat-first redesign. Compatibility is shown as compact annotations on chat messages instead of a standalone panel.

### Added

- Inline crafting compatibility annotations across supported chat channels
- Configurable annotation position (before / after message)
- Configurable annotation style: symbol, short text, or both
- Custom icon presets per verdict (Personal, Guild, Incompatible, Unknown)
- Per-channel toggles (Whisper, Trade, Public, Say, Yell, Party, Raid, Instance, Guild, Officer)
- Verdict visibility toggles for each state
- Premium settings panel with toggles, segmented controls, and symbol dropdowns
- Debug window with pipeline checklist, log, and copy support (`/rd debug`)
- Self-test harness using live realm/guild APIs plus synthetic cases (`/rd test`)
- Compatibility result caching for frequent chat lookups
- Shared styled UI helpers (close button, scroll frames)

### Changed

- Presentation is chat-first; the old main compatibility panel is removed
- Guild and Officer channels are off by default
- Default annotation style is symbol-only after the message
- Slash commands reworked around settings, toggle, check, debug, and test
- TOC Notes and Interface version aligned with Midnight 12.1.x (`120100`)

### Fixed

- Annotations are applied to the message body only so Blizzard player hyperlinks stay intact
- Own messages are skipped
- Guild roster and compatibility caches invalidate on guild/login changes

## 0.0.4 — 2026-09-20

- **Guild auto-detection** — whisperers and targets who are in your guild are detected automatically; no more manual checkbox
- Guild verdict is now green (positive outcome): "GUILD ORDER AVAILABLE"
- Inline whisper verdict now displays under the whisper in the correct chat frame
- Notify checkbox and `/rd notify` command stay in sync
- Scale-aware window position — panel appears in the same spot across characters with different UI scales
- Fixed: `/rd` commands no longer error when typed before addon finishes loading
- Fixed: chat hook no longer throws on modern clients
- Added debug commands: `/rd rostertest`, `/rd rosterdump`, `/rd rosterrebuild`, `/rd posdebug`

## 0.0.3 — 2026-09-20

- Two-row button layout for better readability
- Added Reset button to reposition the panel
- Search icon in the realm input field
- Whisper verdict now uses a chat message filter (appears under the whisper, in the correct chat frame)

## 0.0.2 — 2026-09-20

- Added "Notify on whisper" toggle (panel checkbox + `/rd notify`)
- Whisper verdict now appears inline in chat, under the actual whisper line
- Notify is off by default — silent unless you opt in
- Fixed verdict message wording to be self-explanatory out of context

## 0.0.1 — 2026-09-20

- Initial release
- Personal vs. guild order verdict
- Whisper auto-fill
- Target detection
- Realm search input
- Minimap button
