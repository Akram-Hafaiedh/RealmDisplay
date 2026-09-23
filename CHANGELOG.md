# Changelog


## 0.0.5 — 2026-09-23

- Fixed: inline whisper verdict was spamming duplicate lines and leaking into the wrong chat frame (e.g. General) — it was hooking `OnEvent` on every chat window instead of filtering the message once. Now uses `ChatFrame_AddMessageEventFilter`, so it fires exactly once per whisper and appends to that message directly.

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