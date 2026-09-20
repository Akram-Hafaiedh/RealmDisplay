# TODOs

Planned features and improvements for RealmDisplay. Nothing here is committed to a release — this is a parking lot for ideas worth revisiting.

Order is loosely by priority, not by effort.

---

## Tier 1 — Quality of life

- [ ] **Whisper-triggered auto-focus** — bring the panel to front when a whisper arrives while it's hidden. Configurable toggle, default off.
- [ ] **Ping display in footer** — was cut during the v0.0.x redesign. Add back as a small `(45ms)` suffix in the footer, color-coded green/yellow/red.
- [ ] **Copy verdict button** — separate from the click-to-copy verdict box. Some users prefer an explicit button.
- [ ] **Right-click minimap** to toggle notify, left-click to toggle panel — reduces reliance on slash commands.
- [ ] **Panel opacity slider** — the current `C_BG[4] = 0.92` is hardcoded. Expose a slider in a small settings panel.
- [ ] **Realm input autocomplete** — as you type, show a dropdown of matching realms from (a) your connected cluster and (b) a recently-seen-realms cache built from whispers and targets. Tab or click to accept. Does **not** cover all realms — see "Rejected" for why.
- [ ] **"Realm Check" on player unit context menu** — right-click a player (target, raid frame, party frame) → "Realm Check" → fills the panel with their realm and guild status. Uses the unit popup menu API, no taint risk.

## Tier 2 — Expand the use case

- [ ] **BNet whisper support** — `CHAT_MSG_BN_WHISPER` currently ignored. BNet friends may be on any realm, but the whisper carries no realm info, so we'd need a name-to-realm lookup cache built from `/who` or guild roster.
- [ ] **Faction check** — personal orders are cross-faction in modern retail, but guild orders require same-faction guild. Add faction to the verdict when detectable.
- [ ] **Tooltip on chat name hyperlinks** — hovering a player name in chat shows a verdict line in their tooltip. Risky — potential taint issues with `SetItemRef`.
- [ ] **Saved customer history** — remember the last N whisperers/targets for quick re-check. Useful if a customer comes back later.
- [ ] **Slash command aliases** — `/rd c <realm>` short form for `/rd check`.
- [ ] **"Realm Check" on chat player links** — right-click a player name in chat → "Realm Check". Feasible via `ChatFrame_OnHyperlinkShow`, but risky: chat hyperlink hooks are a known taint source and can break the default right-click menu if they fail. Try the unit popup version first; only pursue this if users ask.

## Tier 3 — Polish & infrastructure

- [ ] **Minimal settings panel** — probably use Blizzard's `Settings` API rather than a custom frame. Just: theme toggle, ping on/off, notify default, panel opacity.
- [ ] **Localization framework** — `Locales/enUS.lua` etc. for UI strings. Only worth it when non-English users ask.
- [ ] **LibSharedMedia font support** — allow users to pick the panel font from their LSM-registered fonts. Low value unless requested.
- [ ] **CurseForge project icon** — 256×256 PNG derived from a Blizzard crafting icon. Needed for a polished CF page.
- [ ] **Screenshot folder** — a `docs/` folder with 2-3 PNGs of the panel in different states, referenced from the README.

## Tier 4 — Big if ever

- [ ] **Browse-all dropdown** — we removed the static realm database in favor of search-only. If users complain, we could bring it back via a lightweight, auto-updated name list.
- [ ] **External data sync** — companion desktop app that writes `RealmData.lua` on update. Overkill; only if the search-only model fails.
- [ ] **Crafting order integration** — inspect an open crafting order window and show a verdict for the customer automatically. Requires `C_CraftingOrders` API, which is fragile between patches.

---

## Rejected / won't do

Ideas that were considered and intentionally dropped. Documented so we don't relitigate them later.

- ❌ **Character/gold tracking** — different addon's problem.
- ❌ **Theme toggle in main panel** — too much surface area; if added, it goes in a settings panel.
- ❌ **Manual guild checkbox** — replaced by auto-detection via the roster cache. The checkbox forced users to confirm something the addon can determine itself.
- ❌ **Static realm database** — needed manual regeneration on Windows-only scripts. Replaced by `GetAutoCompleteRealms()`.
- ❌ **LibRealmInfo dependency** — the library is 6+ years stale. `GetAutoCompleteRealms()` is live and accurate.
- ❌ **Custom TTF fonts** — SystemFont_* matches the AlterArena/WeeklyKnowledge look and needs no shipping weight.
- ❌ **Full realm autocomplete** — would require shipping a static list of ~1,100 realm names. We removed the static database in favor of `GetAutoCompleteRealms()` (live, always accurate, but scoped to the player's own cluster). Autocomplete is therefore limited to the cluster + a local recent-realms cache. If users complain, revisit with a lightweight, rarely-updated name list.

---

## How to use this file

When an idea strikes, add it here under the right tier. When it's time to build something:

1. Move the item to the top of its tier (or promote it if it feels bigger).
2. Cut a branch named after it (e.g. `feat/whisper-autofocus`).
3. Build it, test it, ship it as the next version bump.
4. Check the box or delete the line — no history needed, the CHANGELOG records what shipped.

Don't let this list grow into a design doc. If an item needs more than 2-3 lines to explain, it deserves its own file or its own conversation.