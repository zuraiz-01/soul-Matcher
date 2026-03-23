# SoulMatch Architecture

## Folder Structure

```text
lib/
  main.dart
  firebase_options.dart
  app/
    app.dart
    bindings/
      initial_binding.dart
      auth_binding.dart
      onboarding_binding.dart
      home_binding.dart
      profile_binding.dart
      chat_binding.dart
      settings_binding.dart
    core/
      constants/app_constants.dart
    data/
      models/
        app_user.dart
        swipe_action.dart
        match_model.dart
        chat_message.dart
      repositories/
        auth_repository.dart
        user_repository.dart
        discover_repository.dart
        chat_repository.dart
    modules/
      splash/
      onboarding/
      auth/
      profile/
      home/
      discover/
      matches/
      chat/
      settings/
    routes/
      app_routes.dart
      app_pages.dart
    services/
      firebase_notification_service.dart
    theme/
      app_theme.dart
      theme_controller.dart
    widgets/
      primary_button.dart
      app_text_field.dart
      app_loader.dart
      empty_state.dart
```

## Architecture Style

- Presentation: `modules/*/*_page.dart` and reusable widgets
- Application state: GetX controllers per feature (single responsibility)
- Dependency injection: GetX bindings (`Get.lazyPut`)
- Data access: repositories (`app/data/repositories`)
- Domain models: plain immutable models (`app/data/models`)
- Backend: Firebase Auth + Firestore + Storage + FCM

## User Flow

1. `Splash` checks auth state and user profile status.
2. If not logged in -> `Auth`.
3. If logged in but onboarding incomplete -> `Onboarding`.
4. If onboarding done but profile incomplete -> `Profile Setup`.
5. Completed users enter `Home`:
   - Discover swipe deck
   - Matches list
   - Me tab
6. Chat opens from match list in real time.
7. Settings allows theme switch, logout, delete account.

## GetX Routes

- `/` -> splash
- `/auth` -> login/signup
- `/phone-auth` -> phone OTP
- `/onboarding` -> intro flow
- `/profile-setup` -> first-time profile
- `/profile-edit` -> edit profile
- `/home` -> main app
- `/chat` -> one-to-one chat (arguments)
- `/settings` -> settings

## Controllers and Bindings

- `SplashController` in `InitialBinding`
- `AuthController` in `AuthBinding`
- `OnboardingController` in `OnboardingBinding`
- `HomeController`, `DiscoverController`, `MatchesController` in `HomeBinding`
- `ProfileController` in `ProfileBinding`
- `ChatController` in `ChatBinding`
- `SettingsController` in `SettingsBinding`

## Firestore Schema

### `users/{uid}`

```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "bio": "string",
  "age": 27,
  "gender": "Woman",
  "interestedIn": "Man",
  "location": "New York",
  "photos": ["url1", "url2"],
  "onboardingCompleted": true,
  "profileCompleted": true,
  "fcmToken": "token",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### `swipes/{uid}/actions/{targetUid}`

```json
{
  "byUserId": "uid",
  "targetUserId": "uid",
  "action": "pass | like | super_like",
  "createdAt": "timestamp"
}
```

### `matches/{matchId}`

```json
{
  "users": ["uidA", "uidB"],
  "createdAt": "timestamp",
  "lastMessage": "text",
  "lastMessageAt": "timestamp",
  "unreadCount": {
    "uidA": 0,
    "uidB": 3
  }
}
```

### `matches/{matchId}/messages/{messageId}`

```json
{
  "matchId": "uidA_uidB",
  "senderId": "uidA",
  "receiverId": "uidB",
  "text": "hello",
  "imageUrl": null,
  "createdAt": "timestamp"
}
```

### `blocks/{uid}/blocked/{targetUid}`

```json
{
  "targetUid": "uid",
  "createdAt": "timestamp"
}
```

### `reports/{reportId}`

```json
{
  "reporterUid": "uid",
  "reportedUid": "uid",
  "reason": "abuse/spam/etc",
  "createdAt": "timestamp"
}
```
