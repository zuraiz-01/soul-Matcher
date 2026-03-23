# Firebase Setup (SoulMatch)

## 1. Create Firebase project

1. Create project in Firebase console.
2. Enable Authentication providers:
   - Email/Password
   - Google
   - Phone
3. Create Firestore database (production mode).
4. Enable Firebase Storage.
5. Enable Firebase Cloud Messaging.

## 2. Register apps

1. Add Android and iOS apps in Firebase.
2. Download and place:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

## 3. FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then replace placeholder `lib/firebase_options.dart` with generated values.

## 4. Android setup

- Ensure `android/build.gradle.kts` and `android/app/build.gradle.kts` include Google services plugin.
- Ensure `minSdk` supports Firebase dependencies (21+ recommended).

## 5. iOS setup

- Run `pod install` in `ios/`.
- Add push notification capability and background modes.

## 6. FCM integration note

- App receives foreground notifications via `FirebaseNotificationService`.
- For chat push delivery, implement a Cloud Function trigger on
  `matches/{matchId}/messages/{messageId}` that sends notification to receiver `fcmToken`.

## 7. TODO markers in code

- `lib/firebase_options.dart` has TODO placeholders.
- Replace with real config before production builds.
