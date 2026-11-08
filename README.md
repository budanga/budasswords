# Budasswords

A secure, offline-first personal password and private notes manager for **Android** and **Windows**.

Built with **Flutter**, **Firebase** (Auth + Firestore), **AES-256-GCM** and **Argon2id**. The server only ever stores ciphertext.

---

## Features

- **Master password**: a single master password unlocks the vault. The encryption key is derived on-device with Argon2id and never leaves it.
- **End-to-end encryption**: every field (title, URL, content) is encrypted with AES-256-GCM and a fresh random IV.
- **Biometrics (Android)**: the fingerprint prompt opens automatically on the unlock screen, before the master password field.
- **Auto-lock**: the key is wiped from memory after inactivity (1 min – 3 h, configurable) and whenever the app goes to the background.
- **Offline-first**: entries live in a local Drift (SQLite) database and work without a connection.
- **Cloud sync**: optional sync through Firestore. Pending offline edits are never overwritten by an older server copy, and offline deletions are queued.
- **Link a cloud account**: connect an existing local vault to a Firebase account without wiping it. Linking is refused if the cloud vault uses a different master password.
- **Import / export**: import from Bitwarden JSON exports; export to a JSON backup.
- **Safe clipboard**: copied secrets are cleared after 30 seconds.
- **Admin dashboard**: user directory and connection diagnostics, restricted to accounts with `role: admin`.
- **Spanish and English** interface.

---

## Tech Stack

| Area | Technology |
|---|---|
| Framework | Flutter 3.x (Dart ≥ 3.3) |
| State management | Riverpod |
| Routing | GoRouter |
| Local database | Drift (SQLite) |
| Backend | Firebase Auth + Cloud Firestore |
| Cryptography | `cryptography` (Argon2id, AES-256-GCM) |
| Secure storage | `flutter_secure_storage` (Android Keystore / Windows DPAPI) |
| Biometrics | `local_auth` |

---

## Getting Started

### 1. Prerequisites

- [Flutter 3.x stable](https://docs.flutter.dev/get-started/install)
- A [Firebase](https://console.firebase.google.com) project with **Email/Password** authentication and **Cloud Firestore** enabled
- [Firebase CLI](https://firebase.google.com/docs/cli) and [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)

### 2. Clone and install

```bash
git clone git@github.com:budanga/budasswords.git
cd budasswords
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` generates the Drift code (`*.g.dart`, not committed).

### 3. Configure Firebase

```bash
firebase login
flutterfire configure --project=<your-project-id> --platforms=android,windows
```

This writes `lib/firebase_options.dart` and `android/app/google-services.json` (the latter is git-ignored).

### 4. Deploy the Firestore security rules

The rules live in [`firestore.rules`](firestore.rules) and are registered in `firebase.json`:

```bash
firebase deploy --only firestore:rules --project <your-project-id>
```

They enforce:

- each user can only read and write their own vault entries and vault metadata (`users/{uid}/meta`);
- new profiles are always created with `role: 'user'`, and clients can never change their own role;
- admins can read user profiles and count entries, but never another user's salt or proof.

### 5. Make yourself admin (optional)

Roles cannot be set from the app. In the Firebase console, open `users/{your-uid}` in Firestore and set `role` to `admin`.

### 6. Run

```bash
flutter run -d android
```

```bash
flutter run -d windows
```

### 7. Test

```bash
flutter analyze
```

```bash
flutter test
```

### 8. Build a release

```bash
flutter build apk --release
```

```bash
flutter build windows --release
```

To update an installed Android app **without losing the local vault**, install over it instead of uninstalling first:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

> The Android release build is currently signed with the debug key. Set up your own signing config before distributing it.

---

## Security Model

| Layer | Mechanism |
|---|---|
| Key derivation | Argon2id (64 MB memory, 3 iterations, 32-byte random salt) |
| Vault encryption | AES-256-GCM, random 12-byte IV per field |
| Master password check | Encrypted proof blob; the password itself is never stored |
| Key in memory | Only while unlocked; wiped on lock, auto-lock and background |
| Local secrets | Salt and proof in `flutter_secure_storage` (Keystore / DPAPI) |
| Server storage | Ciphertext, salt and proof only; Firebase cannot read entries |
| Access control | Firestore rules (owner-only vault data, immutable roles) |
| Account vs. vault | The Firebase account password and the master password are separate |

Known limitations:

- Exports are **plain-text JSON**. Store them securely and delete them when no longer needed.
- Screenshots are not blocked on Android yet.
- On Windows, clearing the clipboard does not remove entries from the clipboard history (Win+V).

---

## Project Structure

```
lib/
├── core/        # constants, localization (ES/EN), clipboard and toast helpers
├── crypto/      # Argon2id key derivation, AES-GCM vault cipher
├── data/
│   ├── local/   # Drift database, tables and VaultDao
│   └── remote/  # Firestore API (entries, vault metadata, profiles)
├── domain/      # models (VaultEntry, UserSession)
├── providers/   # Riverpod: auth, vault sync, admin, locale, pinned entries
└── ui/          # router, theme, screens and widgets
test/            # crypto, sync, router and UI tests
firestore.rules  # Firestore security rules
```

---

## License

Personal use. MIT License.
