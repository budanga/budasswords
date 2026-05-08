# Budasswords

A production-quality, secure, and offline-first cross-platform personal password manager for Android and Windows.

Built with **Flutter**, **Supabase**, **AES-256-GCM**, and **Argon2id**.

---

## Features

- **Master-Password Authentication**: Secure login using a single master password, hashed with Argon2id.
- **Biometric-First Flow**: Enhanced security on mobile by requiring biometric validation before unlocking the password field.
- **Encryption**: Vaults are encrypted using AES-256-GCM with per-entry random IVs.
- **Intelligent Auto-lock**: Automatically wipes encryption keys from memory after a configurable period of inactivity.
- **Offline-First Architecture**: Built with Drift (SQLite) for local storage. Access your passwords anytime, anywhere.
- **Real-Time Sync**: Seamlessly sync across your devices using Supabase, complete with conflict resolution.
- **Import Utility**: Easily migrate from **Bitwarden** with a fully localized English import flow.

---

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Routing**: GoRouter
- **Database (Local)**: Drift (SQLite)
- **Database (Remote)**: Supabase (PostgreSQL)
- **Cryptography**: `cryptography` & `pointycastle` (Argon2id, AES-256-GCM)
- **Secure Storage**: `flutter_secure_storage` (Keystore / DPAPI)
- **Animations**: `flutter_animate`

---

## Quick Start

### 1. Prerequisites

- [Flutter 3.x stable](https://docs.flutter.dev/get-started/install/windows)
- [Supabase account](https://supabase.com) (free tier is fine)
- [Supabase CLI](https://supabase.com/docs/guides/cli)

### 2. Clone & Install

```bash
git clone git@github.com:budanga/budasswords.git
cd budasswords
flutter pub get
# Generate DB and Provider code
dart run build_runner build --delete-conflicting-outputs
```

### 3. Supabase Setup

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push          # runs migrations/001_initial_schema.sql
```

Copy your **Project URL** and **anon public key** from the Supabase dashboard.

### 4. Configure Credentials

Edit `lib/core/constants/env.dart`:

```dart
class Env {
  static const supabaseUrl  = 'https://YOUR_PROJECT.supabase.co';
  static const supabaseAnon = 'YOUR_ANON_KEY';
}
```

> **⚠️ Never commit `env.dart` — it is excluded via `.gitignore`.**


### 5. Run the App

```bash
# Android device / emulator
flutter run -d android

# Windows Desktop
flutter run -d windows
```

### 6. Build Release

```bash
# Android APK (split by ABI for smaller files)
flutter build apk --release --split-per-abi

# Windows MSIX / EXE
flutter build windows --release
```

---

## Security Model

Budasswords is built from the ground up with a zero-knowledge security model.

| Layer | Mechanism |
|---|---|
| **Key Derivation** | Argon2id (64 MB memory, 3 iterations) |
| **Vault Encryption** | AES-256-GCM, with per-entry random IV |
| **Auto-lock Timer** | Clears memory and UI state after inactivity (1m - 3h) |
| **Key Storage** | In-memory only; actively wiped on lock |
| **Salt & Token Storage** | `flutter_secure_storage` (Android Keystore / Windows DPAPI) |
| **Transport Security** | Supabase TLS 1.3 |
| **Server Storage** | Opaque ciphertext only. The server cannot read your data. |

---

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for full design documentation.

---

## License

Personal use. MIT License.
