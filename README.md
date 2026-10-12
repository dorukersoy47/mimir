# Mímir

My personal assistant, as an iOS app. One app, many small tools, added one at a time as I need them.

## Features

| Feature   | Status  | What it does                                        |
|-----------|---------|-----------------------------------------------------|
| Habits    | Done    | Weekly goals, streaks, history, reminders, archive  |
| Converter | Done    | Units, currency, time zones, and more; favorites    |
| Reviews   | Planned | Rate and review games, books, and films             |
| Places    | Planned | Mark the places I've visited on a map (à la *Been*) |

Every feature can be switched off in Settings. A switched-off feature is hidden, and its data is kept.

## Privacy

- **Your data stays yours.** Everything is saved on your iPhone (later, optionally, in your own private iCloud). No accounts, no servers, no analytics.
- **Nothing is shared.** Everyone who installs Mimir has their own, completely separate data.
- **The web is read-only.** Features may fetch public info (e.g. currency rates, film details, maps) but never upload your data.

## Getting started

Requires Xcode 27 and iOS 27.

1. Clone the repo and open `Mimir.xcodeproj` in Xcode.
2. Building your own copy? In the Mimir target's **Signing & Capabilities**, set **Team** to your own and change the **Bundle Identifier** (e.g. `com.yourname.Mimir`).
3. Pick a simulator or your iPhone from the device menu at the top of the window, then press **⌘R**.

### Running on an iPhone with a free Apple ID

1. Xcode → Settings → Accounts: sign in with your Apple ID.
2. Mimir target → **Signing & Capabilities**: set Team to your *Personal Team*.
3. Connect the iPhone with a cable, unlock it, and tap **Trust**.
4. On the iPhone: Settings → Privacy & Security → **Developer Mode** → on (it restarts).
5. Select the iPhone in Xcode and press **⌘R**.
6. The first time, the iPhone blocks the app: Settings → General → VPN & Device Management → trust your developer profile.

A free account's install expires after **7 days**. Plug in and press ⌘R again; your data is kept.

## Roadmap

- [x] Planning & README
- [x] App shell (home screen, feature list, Settings with on/off switches)
- [x] Habits
- [x] Converter
- [ ] Reviews
- [ ] Places
- [ ] UI design pass
- [ ] Private iCloud sync

## Development

How the code is organised, the rules it follows, and how to add a feature: see [DEVELOPMENT.md](DEVELOPMENT.md).
