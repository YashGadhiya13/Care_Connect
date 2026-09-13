# CareConnect

A simple Flutter + Firebase app for community volunteer matching: people post
requests for help (checkups, errands, rides, groceries), and other users
volunteer to fulfill them.

## Status

All app code is written and compiles. **Firebase is not yet connected** —
that step needs your own Google/Firebase login, which can't be done for you
automatically. Follow the steps below (should take ~10 minutes).

## 1. Install the FlutterFire CLI (one-time)

```
dart pub global activate flutterfire_cli
```

## 2. Log in to Firebase

```
firebase login
```

This opens a browser window for you to sign in with your Google account.

## 3. Connect this project to Firebase

From the project root:

```
flutterfire configure
```

- Choose **"Create a new project"** (or select an existing one).
- Select the platforms you want (Android / iOS / Web).
- This overwrites `lib/firebase_options.dart` with your real project's
  config and registers the app with Firebase automatically.

## 4. Enable Email/Password sign-in

In the [Firebase Console](https://console.firebase.google.com):
- Open your project → **Build → Authentication → Sign-in method**
- Enable **Email/Password**

## 5. Create the Firestore database

- In the console: **Build → Firestore Database → Create database**
- Start in **test mode** for development (the app ships with rules in
  `firestore.rules` that you should deploy before showing this to anyone
  else — see below).

## 6. Deploy the security rules

```
firebase use --add        # pick the project you just created
firebase deploy --only firestore:rules
```

## 7. Run the app

```
flutter pub get
flutter run
```

## App structure

- `lib/models/` — `AppUser`, `HelpRequest` data models
- `lib/services/` — `AuthService` (Firebase Auth), `FirestoreService` (Firestore reads/writes)
- `lib/providers/auth_provider.dart` — app-wide auth/profile state (via `provider`)
- `lib/screens/` — Splash, Login/Signup, Requests Feed, My Activity, Create Request, Request Detail, Profile
- `lib/theme/app_theme.dart` — colors and Material 3 theme
- `firestore.rules` — security rules (users can only edit their own profile/requests)

## Smoke test after setup

1. Sign up with an email/password → you land on the Requests Feed.
2. Tap **New Request**, fill the form, post it.
3. Sign up with a second email (or use a second device/emulator) and confirm
   the request shows up in the feed.
4. Tap it → **Accept & Help** → status changes to "Accepted".
5. From either account (owner or volunteer), open it again → **Mark as Completed**.
6. Check the **My Activity** tab on both accounts (Posted by Me / I'm Helping).
7. Edit your profile name/phone from the **Profile** tab and confirm it saves.
