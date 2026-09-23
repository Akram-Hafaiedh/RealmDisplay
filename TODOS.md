# TODO

## Next Major Update — Chat-First Compatibility System

The current compatibility panel will no longer be the primary user interface.

RealmDisplay will become a chat-first addon that automatically displays a compact crafting-order compatibility verdict next to players in chat.

The existing realm and guild detection logic remains the foundation of the addon, but the presentation layer will move from a standalone panel to inline chat annotations.

---

## 1. Chat Annotations

### Core

- [ ] Replace the current standalone whisper verdict system with inline chat annotations.
- [ ] Use WoW chat message filters to modify messages before they are displayed.
- [ ] Detect the sender's character name and realm from each supported chat message.
- [ ] Determine the sender's crafting-order compatibility.
- [ ] Add the compatibility annotation next to the sender's name.
- [ ] Preserve the original player name hyperlink.
- [ ] Preserve normal chat formatting and message content.
- [ ] Avoid creating additional chat lines for verdicts.

### Supported Chat Types

- [ ] Whisper
- [ ] Trade
- [ ] General / public channels
- [ ] Say
- [ ] Yell
- [ ] Party
- [ ] Party Leader
- [ ] Raid
- [ ] Raid Leader
- [ ] Instance / Instance Leader
- [ ] Guild
- [ ] Other relevant chat events where sender information is available

Guild chat should be configurable and disabled by default if there is little practical benefit from annotating guild members.

---

## 2. Verdict Display

The annotation should be compact enough to work naturally in busy chat channels.

### Verdicts

- [ ] Personal order available
- [ ] Guild order available
- [ ] Incompatible
- [ ] Unknown / unable to determine

### Display Examples

Preferred compact format:

    Player-Realm [✓]: Can you craft this?

Alternative:

    [✓] Player-Realm: Can you craft this?

Alternative short-text format:

    Player-Realm [Personal]: Can you craft this?

### Customization

- [ ] Allow the annotation to appear before the player name.
- [ ] Allow the annotation to appear after the player name.
- [ ] Symbol only
- [ ] Short text
- [ ] Symbol + short text
- [ ] Allow users to choose which verdicts are displayed.
- [ ] Allow customization of the short verdict text.
- [ ] Keep the default presentation minimal to avoid chat clutter.

---

## 3. Verdict Details

The compact annotation should provide enough information at a glance while allowing more details when needed.

### Personal

    Same connected realm.
    Personal crafting order available.

### Guild

    Different realm.
    Player is a member of your guild.
    Guild crafting order available.

### Incompatible

    Different realm.
    Player is not in your guild.
    Crafting order is not available.

### Unknown

    The player's realm or guild status could not be determined.

### Details Interaction

- [ ] Add an optional tooltip when hovering the annotation.
- [ ] Show the player's detected realm.
- [ ] Show the detected compatibility reason.
- [ ] Show whether the player was detected as a guild member.
- [ ] Consider a manual detailed player check from the annotation.

---

## 4. Settings / Options Page

The current main compatibility panel will be replaced by a dedicated settings page.

The settings page becomes the main configuration interface for RealmDisplay.

### General

- [ ] Enable / disable chat annotations.
- [ ] Enable / disable the minimap button.
- [ ] Reset addon settings.
- [ ] Reset annotation settings to defaults.

### Chat Channels

Allow annotations to be independently enabled or disabled for each supported chat type.

- [ ] Whisper
- [ ] Trade
- [ ] General / public channels
- [ ] Say
- [ ] Yell
- [ ] Party
- [ ] Raid
- [ ] Instance
- [ ] Guild
- [ ] Other supported channels

Suggested defaults:

- Whisper: enabled
- Trade: enabled
- Public channels: enabled
- Party: enabled
- Raid: enabled
- Instance: enabled
- Guild: disabled

---

## 5. Annotation Customization

### Position

- [ ] Before player name
- [ ] After player name

### Style

- [ ] Symbol only
- [ ] Short text
- [ ] Symbol + short text

### Verdict Visibility

- [ ] Show Personal
- [ ] Show Guild
- [ ] Show Incompatible
- [ ] Show Unknown

### Optional Customization

- [ ] Custom symbol for Personal
- [ ] Custom symbol for Guild
- [ ] Custom symbol for Incompatible
- [ ] Custom symbol for Unknown
- [ ] Custom short text for each verdict

---

## 6. Compatibility / Detection

Keep the existing compatibility engine and adapt it for frequent chat lookups.

- [ ] Keep Blizzard live connected-realm detection.
- [ ] Keep automatic guild membership detection.
- [ ] Add player/realm compatibility caching.
- [ ] Avoid repeatedly rebuilding the guild roster.
- [ ] Handle senders without an explicit realm safely.
- [ ] Handle cross-realm names correctly.
- [ ] Handle duplicate character names from different realms.
- [ ] Handle chat events where realm information is unavailable.
- [ ] Make detection consistent across all supported chat types.

---

## 7. Chat Performance

Because chat annotations may process many messages, the system should avoid unnecessary work.

- [ ] Cache compatibility results.
- [ ] Avoid performing expensive realm/guild checks for every message when the result is already known.
- [ ] Avoid modifying messages that cannot provide a usable sender.
- [ ] Avoid adding annotations when the feature is disabled for that chat type.
- [ ] Ensure filters do not interfere with Blizzard's normal chat handling.
- [ ] Test with high-volume Trade and General chat.

---

## 8. Old Main UI Cleanup

The existing large compatibility panel becomes obsolete once the settings page and chat annotations are complete.

- [ ] Remove the current main compatibility panel.
- [ ] Remove realm search UI from the main panel.
- [ ] Remove customer realm manual-entry workflow.
- [ ] Remove whisper-specific notification UI.
- [ ] Remove redundant verdict display code.
- [ ] Remove obsolete panel positioning code.
- [ ] Keep only UI components that are still useful for configuration or detailed inspection.

---

## 9. Slash Commands

Rework `/rd` around the new chat-first design.

Possible commands:

- [ ] `/rd` — open settings
- [ ] `/rd config` — open settings
- [ ] `/rd toggle` — enable / disable chat annotations
- [ ] `/rd check <player>` — manually check a player
- [ ] `/rd reset` — reset settings
- [ ] `/rd minimap` — toggle minimap button
- [ ] `/rd debug` — debug information

Review and remove commands that only existed for the old main panel.

---

## 10. Future Crafting Intelligence

Potential future feature after the basic annotation system is stable.

- [ ] Detect messages that appear to be crafting requests.
- [ ] Only show compatibility annotations on potentially relevant crafting messages.
- [ ] Detect common crafting-request wording.
- [ ] Detect profession names and crafting-related terms.
- [ ] Allow users to enable/disable crafting-request filtering.

This should remain optional. The initial implementation should annotate based on the chat sender without attempting to interpret message intent.

---

## 11. Future Manual Interaction

- [ ] Manual "check player" action from chat.
- [ ] Right-click/context-menu integration where safely supported.
- [ ] Clickable annotation for detailed compatibility information.
- [ ] Optional detailed compatibility popup.
- [ ] Avoid bringing back the old persistent compatibility panel.

---

## 12. Documentation

- [ ] Update README for the new chat-first workflow.
- [ ] Update usage instructions.
- [ ] Update slash command documentation.
- [ ] Document annotation symbols.
- [ ] Document settings.
- [ ] Add screenshots of annotated chat.
- [ ] Add screenshots of the new settings page.