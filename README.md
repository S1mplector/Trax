# Trax

Trax is a minimal macOS menu bar app for daily expense tracking and no-buy check-ins.

## What It Does

- Log expenses with a day, amount, category, and optional note.
- Mark a day as no-spend when nothing was bought.
- See month-to-date spending, spent days, no-spend days, and the current no-spend streak.
- Create, rename, archive, restore, and remove categories.

## Architecture

The code is split as a small hexagonal app:

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

## Data Location

The live app stores data at:

```text
~/Library/Application Support/Trax/expense-book.json
```
