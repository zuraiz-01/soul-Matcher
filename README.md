# Soul Matcher

Flutter dating app built with GetX + Firebase.

## Prerequisites

- Flutter managed via FVM
- Dart SDK comes from the selected Flutter version

## FVM Setup

1. Install FVM globally (one-time):
   ```bash
   dart pub global activate fvm
   ```
2. Install the pinned SDK for this project:
   ```bash
   fvm install
   ```
3. Use the pinned SDK in this folder:
   ```bash
   fvm use
   ```
4. Run app commands through FVM:
   ```bash
   fvm flutter pub get
   fvm flutter run
   ```

## Project Flutter Version

This project is pinned to Flutter `3.41.2` via `.fvmrc`.

## Windows note
If `fvm use` fails with error `1314` (symlink privilege), either enable Windows Developer Mode or run terminal as Administrator.
Project can still run with:
```bash
fvm flutter pub get
fvm flutter run
```
