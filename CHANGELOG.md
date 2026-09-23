# Changelog

## Unreleased

### Changed

- **Chat-first design** — RealmDisplay is being redesigned around inline chat compatibility annotations instead of a standalone compatibility panel.
- **Inline player verdicts** — compatibility information will be displayed directly alongside the player who sent the message.
- **Cross-channel compatibility** — annotations will support whispers, Trade, public channels, party, raid, instance, and other supported chat types.
- **Compact annotations** — verdicts will use a small symbol and/or short text instead of generating a separate verdict message.
- **Settings replaces the main UI** — the current compatibility panel will be replaced by a dedicated settings/options page.
- **Configurable annotation position** — users will be able to place the verdict before or after the player name.
- **Configurable annotation style** — users will be able to choose between symbol-only, short text, or symbol + short text.
- **Configurable chat channels** — annotations can be enabled or disabled independently for supported chat types.
- **Configurable verdict visibility** — users can choose which compatibility states are displayed.
- **Optional Guild annotations** — Guild chat will be configurable rather than being assumed as a primary use case.
- **Preserved compatibility engine** — connected-realm detection and automatic guild detection remain the foundation of the addon.
- **Reduced UI dependency** — the addon will no longer require opening a persistent panel to determine a player's crafting compatibility.

### Planned

- Replace the current whisper-specific chat handling with a general chat message filtering system.
- Preserve Blizzard player hyperlinks and existing chat formatting.
- Add compatibility result caching for frequent chat lookups.
- Add optional tooltips/details for compatibility annotations.
- Rework slash commands around the chat-first workflow.
- Remove obsolete components of the current compatibility panel.
- Update documentation and screenshots for the new workflow.

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
