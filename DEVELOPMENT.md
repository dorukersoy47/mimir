# Developing Mímir

## Principles

- **Simplest solution wins.** If there's a shorter way, use it.
- **No clutter.** No speculative code, no unused abstractions, no comments that restate the code.
- **Features are independent.** A feature never knows another one exists.
- **Apple-only stack.** SwiftUI + SwiftData, no third-party dependencies.
- **Native UI first.** Use system components, painted in the app's colors (see [Look](#look)).
- **Privacy is a rule.** User data never leaves the device, except later to the user's own private iCloud. Web lookups send only what the lookup needs (e.g. search words). See [Privacy](README.md#privacy).

## Tech stack

- SwiftUI, SwiftData, UserNotifications. No dependencies.
- Web lookups (URLSession, no keys, no accounts): [Frankfurter](https://frankfurter.dev) for currency rates, Wikipedia for review search and covers.
- Bundled data: provinces from [GeoNames](https://www.geonames.org) (CC BY 4.0, credited in the app) and country borders from [Natural Earth](https://www.naturalearthdata.com) (public domain), for Places.
- Xcode 27 (Swift 6.4 compiler, Swift 5 language mode), iOS 27, iPhone only.

## Architecture

```
mimir/
├── README.md
├── DEVELOPMENT.md
├── Mimir.xcodeproj
└── Mimir/
    ├── MimirApp.swift     # entry point, sets up storage and the look
    ├── Tabs.swift         # the floating tab bar: Mímir + every feature
    ├── Home.swift         # Mímir's tab: face, greeting, gear to Settings
    ├── Theme.swift        # the two looks, serif titles, icon tiles
    ├── Features.swift     # the one list of features
    ├── Settings.swift     # look, feature switches + each feature's own section
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
        └── Places/
            ├── Places.swift     # feature entry, country list, a country's provinces
            ├── Place.swift      # data: visits, countries, provinces
            ├── PlaceMap.swift   # the world map
            └── Places.json      # every country's provinces and outline
```

The `Mimir/` folder is synced with Xcode: any file added there on disk shows up in the project automatically.

### How a feature works

- One feature = one file in `Mimir/Features/`.
- That file holds everything the feature needs: its data models, its screens, and its `Feature` entry (name, icon, data models, screen, and optionally its own section in Settings).
- `Features.swift` is the only place that lists features. The tab bar, Settings, and storage are built from it.
- A feature that's turned off in Settings disappears from the tab bar. Its data is kept, so turning it back on brings everything back.
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

### Look

- **Two looks**, picked in Settings → Appearance: **Dark Green** (the default) and **Beige**. Mímir sits in the middle of the tab bar in both.
- **Colors** live in `Assets.xcassets`. Each has a light value (Beige) and a dark value (Dark Green); a look just switches the app to light or dark mode. `Page` is the background, `Card` the list rows, `Ink`/`InkSoft` the text, `AccentColor` the tint and Mímir's face, `Tile`/`Beige` the icon tiles.
- **Every screen** gets `.containerBackground(.page, for: .navigation)`, and each list section gets `.listRowBackground(Color.card)`. Neither can be set once for the whole app.
- **Sheets** use `.scrollContentBackground(.hidden)` and `.presentationBackground(.page)` instead, because app-wide settings don't reach them.
- **Tab bar:** custom, because the system one can't be colored. It floats over the screens, and lists get extra bottom margin so they scroll past it.

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

### Places

- **Provinces, not countries:** you tick the provinces you've been to (Turkey's 81 provinces, the US states, Germany's 16 states…). A country is **visited** once one province is ticked and **complete** once all are. A country with no provinces counts as its own single one.
- **Map:** a flat world map drawn by the app. Countries are filled by progress: card colour (none yet), half accent (some), accent (complete). Tapping a country opens it.
- **List:** every country, grouped by continent, with `3/81` once started and a seal once complete. Search matches countries and provinces.
- **Data:** `Places.json` is bundled, so Places never goes online. It holds each country's provinces (GeoNames first-level divisions) and outline (Natural Earth 1:50m, Miller projection on a 2000 × 986 grid, simplified). Country names and continents come from Apple's `Locale`.
- **Saved:** one `PlaceVisit` per ticked province, holding its GeoNames id (`TR.34`). When updating `Places.json`, keep the ids, or ticks are lost.
- **Left out on purpose:** visit dates, notes, a wishlist, zooming the map, cities.

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
