# Trax

Trax is a minimal macOS menu bar app for daily expense tracking.

## What It Does

- Log expenses with a day, amount, category, and optional note.
- Mark a day as no-spend when nothing was bought.
- See month-to-date spending, spent days, no-spend days, and the current no-spend streak.
- Create, rename, archive, restore, and remove categories.
- Mark categories as essential or non-essential for clearer no-buy review.
- Set the currency used for displayed amounts.
- Persist the spending breakdown view mode: list, bars, or donut.
- Optionally launch Trax at login from Settings.

## Architecture

The code is split as a small hexagonal application:

- `TraxDomain`: entities, value objects, and business rules.
- `TraxApplication`: use cases, snapshots, and repository ports.
- `TraxFilePersistence`: JSON file repository adapter.
- `TraxApp`: SwiftUI menu bar UI adapter and composition root.

The domain layer does not import SwiftUI or persistence. The application layer depends only on the domain and a repository protocol. The app and file persistence are replaceable adapters.

## Run During Development

```sh
swift run Trax
```

This builds and runs the SwiftUI menu bar extra from Swift Package Manager.

## Build a Menu Bar App Bundle

```sh
Scripts/package_app.sh release
open build/Trax.app
```

The generated app bundle uses `LSUIElement`, so it behaves as a menu bar app without a Dock icon.
The packaging script also adds the app icon and ad-hoc signs the bundle for local use.

## Build a DMG

```sh
Scripts/package_dmg.sh release
open ~/Desktop/Trax.dmg
```

The script creates `build/Trax.dmg` and copies it to your Desktop.

## Data Location

The live app stores data at:

```text
~/Library/Application Support/Trax/expense-book.json
```
