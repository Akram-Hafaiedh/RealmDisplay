# RealmDisplay

Crafting-order compatibility, right in your chat.

RealmDisplay annotates chat messages so you can see whether a player can take a **personal** crafting order or only a **guild** order (or neither), based on connected realms and guild membership.

## Features

- Inline compatibility annotations on chat messages
- Connected-realm detection (live cluster)
- Automatic guild membership detection
- Verdicts: Personal · Guild · Incompatible · Unknown
- Configurable position (before / after message)
- Configurable style: symbol, short text, or both
- Custom icon per verdict
- Per-channel toggles
- Settings panel + minimap button
- Debug window and self-test (`/rd debug`, `/rd test`)

## How it works

| Verdict | Meaning |
|---------|---------|
| **Personal** | Same connected realm → personal order available |
| **Guild** | Different realm, but in your guild → guild order available |
| **Incompatible** | Different realm, not in guild |
| **Unknown** | Realm/guild could not be determined |

Default style is a compact symbol after the message. You can switch to text or symbol+text and pick icons for each verdict.

## Supported chat

Whisper, Trade, Public channels, Say, Yell, Party, Raid, Instance, Guild, Officer  
(Guild and Officer are off by default.)

## Configuration

`/rd` or the minimap button opens settings:

- Enable/disable annotations
- Annotation position and style
- Symbols for each verdict
- Which verdicts to show
- Per-channel enable/disable
- Minimap button

## Slash commands

| Command | Description |
|---------|-------------|
| `/rd` / `/rd config` | Open settings |
| `/rd toggle` | Enable/disable annotations |
| `/rd status` | Show current settings |
| `/rd check <Name-Realm>` | Manual compatibility check |
| `/rd clearcache` | Clear detection caches |
| `/rd minimap` | Toggle minimap button |
| `/rd debug` | Open debug window |
| `/rd test [player]` | Run self-test cases |

## Installation

Install via CurseForge, or copy the `RealmDisplay` folder into `Interface\AddOns`.

## Compatibility

- World of Warcraft **Retail**
- Midnight **12.1.x** (Interface `120100`)

## License

MIT
