# RealmDisplay

Check whether a customer's realm is compatible with yours for crafting orders.

## What it does

Tells you at a glance whether you can serve a customer via:
- **Personal order** — same connected realm
- **Guild order** — different realm, but you share a guild
- **Neither** — incompatible

## How to use

1. Install the addon
2. `/rd` to open the panel
3. Type the customer's realm name (or whisper auto-fills it)
4. Read the verdict

## Slash commands

- `/rd` — toggle panel
- `/rd check <realm>` — verdict in chat
- `/rd target` — use current target
- `/rd clear` — clear customer
- `/rd whisper` — toggle whisper auto-fill
- `/rd reset` — reset panel position
- `/rd minimap` — toggle minimap button

## Support

Found a bug or have a suggestion? Open an issue on GitHub: [https://github.com/AkramHafaiedh/RealmDisplay/issues]


## Compatibility

Retail only. Tested on 12.1.0.

## Features

- **Live realm data** — uses Blizzard's `GetAutoCompleteRealms()` API. No static database, no maintenance, always accurate.
- **Whisper auto-fill** — when a customer whispers you, their realm is detected automatically.
- **Target detection** — select a player and fill in their realm and guild status with one click.
- **Minimap button** — quick access via LibDataBroker.
- **Lightweight** — no performance impact, no bloat.

## License

MIT — see LICENSE