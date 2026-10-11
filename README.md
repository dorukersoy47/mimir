# Mimir

My personal assistant, as an iOS app. One app, many small tools, added one at a time as I need them.

## Features

| Feature   | Status  | What it does                                   |
|-----------|---------|------------------------------------------------|
| Habits    | Done    | Weekly goals, streaks, history, reminders, archive |
| Converter | Planned | Convert units, metrics, and more               |
| Reviews   | Planned | Rate and review games, books, and films        |
| Places    | Planned | Mark the places I've visited on a map (à la *Been*) |

## Principles

- **Simplest solution wins.** If there's a shorter way, use it.
- **No clutter.** No speculative code, no unused abstractions, no comments that restate the code.
- **My data stays mine.** It lives on my iPhone (later also in my own private iCloud). No third-party servers, no accounts, nothing shared. The app may read public info from the web, but never uploads my data.
- **Everyone's data is private.** If I share the app, each person's data stays on their own device and iCloud. Nobody sees anyone else's.
- **Every feature can be turned off.** Users switch features on or off in Settings.
- **Features are independent.** A feature never knows another one exists.
- **Apple-only stack.** SwiftUI + SwiftData, no third-party dependencies.
- **Native UI first.** Use system components now; the design pass comes later.

## Architecture

```
mimir/
├── README.md
├── Mimir.xcodeproj
└── Mimir/
    ├── MimirApp.swift     # entry point, sets up storage
    ├── Home.swift         # home screen: the list of features
    ├── Features.swift     # the one list of features
    ├── Settings.swift     # turn features on/off
    ├── Shared/            # code used by 2+ features (empty until needed)
    └── Features/
        ├── Habits/        # outgrew one file, so it's a folder
        │   ├── Habits.swift          # feature entry + list screen
        │   ├── Habit.swift           # data + streak logic
        │   ├── HabitDetail.swift     # stats + history grid
        │   ├── HabitForm.swift       # add / edit
        │   └── HabitReminders.swift  # notifications
        ├── Converter.swift
        ├── Reviews.swift
        └── Places.swift
```

### How a feature works

- One feature = one file in `Mimir/Features/`.
- That file holds everything the feature needs: its data models, its screens, and its `Feature` entry (name, icon, screen).
- `Features.swift` is the only place that lists features. The home screen, Settings, and storage are built from it.
- A feature that's turned off in Settings disappears from the home screen. Its data is kept, so turning it back on brings everything back.
- Data models are kept iCloud-ready: every property has a default value, relationships are optional, and nothing is marked unique.
- When a feature outgrows one file (~300 lines), it becomes a folder with the same name.
- Code moves into `Shared/` only once two or more features actually need it.

### Adding a feature

1. Create `Mimir/Features/Name.swift`.
2. Add it to the list in `Features.swift`.

To remove a feature, delete the file and its line in the list.

## Tech stack

- Swift 6, SwiftUI, SwiftData
- Xcode 27, iOS 27
- Data is saved on the iPhone with SwiftData. Private iCloud sync is planned (it needs a paid Apple Developer account).
- Public web data (e.g. currency rates, film/book/game details, maps) is only read, never written to.

## Getting started

1. Open `Mimir.xcodeproj` in Xcode.
2. Pick a simulator or your iPhone from the device menu at the top of the window.
3. Press **⌘R**.

### Running on my iPhone (free Apple ID)

1. Xcode → Settings → Accounts: sign in with your Apple ID.
2. Project → Mimir target → **Signing & Capabilities**: set Team to your *Personal Team*.
3. Connect the iPhone with a cable, unlock it, and tap **Trust**.
4. On the iPhone: Settings → Privacy & Security → **Developer Mode** → on (it restarts).
5. Select the iPhone in Xcode and press **⌘R**.
6. The first time, the iPhone blocks the app: Settings → General → VPN & Device Management → trust your developer profile.

A free account's install expires after **7 days**. Plug in and press ⌘R again; your data is kept.

## Xcode cheat sheet

| Shortcut | Action                          |
|----------|---------------------------------|
| ⌘R       | Build and run                   |
| ⌘.       | Stop                            |
| ⌘B       | Build only (check for errors)   |
| ⇧⌘K      | Clean build (when things act weird) |
| ⌥⌘P      | Refresh the live preview        |
| ⇧⌘O      | Open any file by name           |
| ⌘0       | Show/hide the left sidebar      |
| ⌥⌘0      | Show/hide the right sidebar     |

## Roadmap

- [x] Planning & README
- [x] App shell (home screen, feature list, Settings with on/off switches)
- [x] Habits
- [ ] Converter
- [ ] Reviews
- [ ] Places
- [ ] UI design pass
- [ ] Private iCloud sync
