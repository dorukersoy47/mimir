# Developing Mímir

## Principles

- **Simplest solution wins.** If there's a shorter way, use it.
- **No clutter.** No speculative code, no unused abstractions, no comments that restate the code.
- **Features are independent.** A feature never knows another one exists.
- **Apple-only stack.** SwiftUI + SwiftData, no third-party dependencies.
- **Native UI first.** Use system components now; the design pass comes later.
- **Privacy is a rule.** User data never leaves the device, except later to the user's own private iCloud. Web lookups send only what the lookup needs (e.g. search words). See [Privacy](README.md#privacy).

## Tech stack

- SwiftUI, SwiftData, UserNotifications. No dependencies.
- Web lookups (URLSession, no keys, no accounts): [Frankfurter](https://frankfurter.dev) for currency rates, Wikipedia for review search and covers.
- Xcode 27 (Swift 6.4 compiler, Swift 5 language mode), iOS 27, iPhone only.

## Architecture

```
mimir/
├── README.md
├── DEVELOPMENT.md
├── Mimir.xcodeproj
└── Mimir/
    ├── MimirApp.swift     # entry point, sets up storage
    ├── Home.swift         # home screen: the list of features
    ├── Features.swift     # the one list of features
    ├── Settings.swift     # feature switches + each feature's own section
    ├── Shared/            # code used by 2+ features (created when first needed)
    └── Features/
        ├── Habits/        # outgrew one file, so it's a folder
        │   ├── Habits.swift          # feature entry + list screen
        │   ├── Habit.swift           # data + streak logic
        │   ├── HabitDetail.swift     # stats + history grid
        │   ├── HabitForm.swift       # add / edit
        │   └── HabitReminders.swift  # notifications
        ├── Converter/
        │   ├── Converter.swift            # feature entry, favorites, category list
        │   ├── ConverterCategories.swift  # every category and its units
        │   ├── ConverterScreen.swift      # From → To screen + unit picker
        │   └── ConverterRates.swift       # currency rates download
        ├── Reviews/
        │   ├── Reviews.swift       # feature entry, the four kinds, Settings section
        │   ├── Review.swift        # data, kinds, rating themes
        │   ├── ReviewList.swift    # one kind's tier list + to-do list
        │   ├── ReviewDetail.swift  # rating, review, finished date
        │   └── ReviewAdd.swift     # Wikipedia search
        └── Places.swift
```

The `Mimir/` folder is synced with Xcode: any file added there on disk shows up in the project automatically.

### How a feature works

- One feature = one file in `Mimir/Features/`.
- That file holds everything the feature needs: its data models, its screens, and its `Feature` entry (name, icon, data models, screen, and optionally its own section in Settings).
- `Features.swift` is the only place that lists features. The home screen, Settings, and storage are built from it.
- A feature that's turned off in Settings disappears from the home screen. Its data is kept, so turning it back on brings everything back.
- When a feature outgrows one file (~300 lines), it becomes a folder with the same name. File and type names must be unique across the app, so prefix them with the feature (`HabitForm`, not `Form`).
- Code moves into `Shared/` only once two or more features actually need it.

### Adding a feature

1. Create `Mimir/Features/Name.swift` with an `extension Feature { static let name = Feature(...) }`.
2. Add `.name` to the list in `Features.swift`.

To remove a feature, delete the file and its entry in the list.

### Data rules

- Models stay iCloud-ready: every property has a default value, relationships are optional, and nothing is marked unique.
- Adding a property with a default value is safe; existing data upgrades automatically. Renaming or removing a property needs a migration.
- Small settings (like the feature switches) use `@AppStorage`, which is saved on the device.

## Features

### Habits

- **Goal:** 1–7 times a week; 7 means every day.
- **Finished** = ticked today, or this week's goal is reached. Finished habits sink to the bottom of their section and fade.
- **List number:** every-day habits show `🔥 N days`; weekly habits show `x/y this week` until the goal is met, then `🔥 N weeks`.
- **Streak:** days (every-day habits) or weeks (weekly habits) in a row the goal was met. Today / this week only counts once met, and never breaks a streak while still open.
- **History:** GitHub-style grid, one column per week. Tapping a past day toggles it.
- **Reminders:** optional time per habit; fires only on days the habit is still open. Scheduled up to a week ahead (iOS allows 64 pending) and refreshed whenever Habits is opened or changed.
- **Archive:** swipe a habit to archive it. It's hidden and its reminders stop, but its history is kept under "Archived".
- **Left out on purpose:** icons/colors, reordering, notes, a stats page, one-off to-dos.

### Converter

- **Categories:** Everyday (length, weight, temperature, volume, area, speed, duration), Money & Time (currency, time zones), More (data, energy, power, pressure, angle, fuel economy).
- **Search** on the category list also matches units, currencies, and cities ("lira" → Currency, "Tokyo" → Time Zones).
- **Screen:** From → To. Every unit picker is a searchable list. ⇅ swaps, ☆ favorites.
- **Remembers** the last pair per category. The first two units in a category's list are its default pair.
- **Units** use Apple's `Dimension` classes. Each unit has its own English name, which is also its saved id, so never rename one (Apple's own names repeat, e.g. US and UK fluid ounces).
- **Currency:** European Central Bank rates via [Frankfurter](https://frankfurter.dev) (30 currencies, free, no key). Downloaded when Currency opens; the last rates are saved for offline use. It sends no user data.
- **Time zones:** pick a time in one city and see it in another.
- **Favorites:** a saved pair (category + two unit ids), listed at the top. Tapping one opens its category with that pair; swipe to remove.
- **Left out on purpose:** typing sentences ("5 km in miles"), recents, reordering favorites.

### Reviews

- **Kinds:** Films, TV Shows, Books, Games. Each has its own tier list and its own to-do list (To Watch / To Read / To Play).
- **Rating:** four levels, stored as a number (0 = best). The names come from the theme picked in Settings, so renaming never touches data.
- **Themes:** Classic (Masterpiece, Great, Mid, Bad) and Minecraft (Netherite, Diamond, Iron, Dirt). Add one by adding a case to `ReviewTheme`; every theme has four levels.
- **Adding:** + searches Wikipedia (the kind's word, e.g. "film", is added so the right page comes first). Picking a result fills title, description, and cover; "(2021 film)"-style suffixes are dropped. Nothing matches? Add it by hand.
- **Finished date** is set when something is first rated; setting it back to "To Watch" clears it.
- **Covers** are downloaded once and saved with the review. Only the search words go to Wikipedia. Some TV pages have a logo instead of a poster.
- **Left out on purpose:** ranking within a level, custom cover photos, a mixed all-kinds view.

## Workflow

### Xcode cheat sheet

| Shortcut | Action                              |
|----------|-------------------------------------|
| ⌘R       | Build and run                       |
| ⌘.       | Stop                                |
| ⌘B       | Build only (check for errors)       |
| ⇧⌘K      | Clean build (when things act weird) |
| ⌥⌘P      | Refresh the live preview            |
| ⇧⌘O      | Open any file by name               |
| ⌘0       | Show/hide the left sidebar          |
| ⌥⌘0      | Show/hide the right sidebar         |

### Building from the terminal

```sh
xcodebuild -scheme Mimir -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
```
