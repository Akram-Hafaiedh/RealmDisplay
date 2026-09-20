# RealmDisplay

Check whether a customer's realm is compatible with yours for crafting orders.

## What it does

Tells you at a glance whether you can serve a customer via:
- **Personal order** — same connected realm
- **Guild order** — different realm, but you're in the same guild
- **Neither** — incompatible

## How to use

1. Install the addon
2. `/rd` to open the panel
3. Enter the customer's realm name, or let it auto-fill when they whisper you
4. Read the verdict
5. Optional: enable **Notify on whisper** to see the verdict inline in chat as customers message you

Guild membership is detected automatically — if a whisperer or your current target is in your guild, the addon knows.

## Slash commands

- `/rd` — toggle panel
- `/rd check <realm>` — verdict in chat
- `/rd target` — use current target
- `/rd clear` — clear customer
- `/rd copy` — copy verdict to chat
- `/rd whisper` — toggle auto-fill on whisper (default: on)
- `/rd notify` — toggle inline chat verdict on whisper (default: off)
- `/rd reset` — reset panel position
- `/rd minimap` — toggle minimap button

### Debug commands

- `/rd debug` — print realm cluster info
- `/rd rostertest <name>` — test whether a name matches a guild member
- `/rd rosterdump` — dump the first few guild roster entries
- `/rd rosterrebuild` — force rebuild of the guild roster cache
- `/rd posdebug` — show saved panel position and current UI scale

## Features

- **Live realm data** — uses Blizzard's `GetAutoCompleteRealms()` API. No static database, no maintenance, always accurate.
- **Whisper auto-fill** — when a customer whispers you, their realm is detected automatically.
- **Guild auto-detection** — whisperers and targets who are in your guild are recognized automatically.
- **Inline whisper verdict** — optionally print the verdict directly in your chat, right under the whisper.
- **Target detection** — select a player and fill in their realm and guild status with one click.
- **Scale-aware positioning** — the panel appears in the same physical spot on every character, regardless of UI scale.
- **Minimap button** — quick access via LibDataBroker.
- **Lightweight** — no performance impact, no bloat.

## Support

Found a bug or have a suggestion? Open an issue on GitHub: [https://github.com/AkramHafaiedh/RealmDisplay/issues]

## Compatibility

Retail only. Tested on 12.1.0.

## License

MIT — see LICENSE