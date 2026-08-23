# Budasswords - Contexto del Proyecto

## Propósito
Budasswords es un gestor de contraseñas y notas privadas multiplataforma (Android, Windows, etc.) ligero, enfocado en simplicidad, privacidad y cifrado de cero conocimiento (End-to-End Zero Knowledge Encryption).

## Tecnologías Principales
- **Framework**: Flutter (Dart 3.3+)
- **Estado**: Flutter Riverpod (`StateNotifierProvider`, `StreamProvider`)
- **Navegación**: GoRouter
- **Almacenamiento Local**: SQLite vía Drift / Native sqlite3
- **Almacenamiento Seguro**: FlutterSecureStorage
- **Criptografía**:
  - KDF: Argon2id (`cryptography`)
  - Cifrado simétrico: AES-256-GCM (`cryptography`)
- **Backend / Sincronización**: Firebase Authentication + Cloud Firestore
- **Biometría**: `local_auth`

## Objetivos Actuales
- Proveer una experiencia fluida, rápida y segura para guardar cuentas, contraseñas, notas privadas y tarjetas.
- Sincronización multi-dispositivo cifrada punto a punto.
- Autolock y protección activa de memoria y portapapeles.

## Restricciones
- La contraseña maestra nunca sale del dispositivo y nunca se envía a ningún servidor.
- Los datos en Firestore están siempre encriptados con la clave derivada localmente (cero conocimiento).
- La app debe funcionar 100% offline y sincronizar cuando haya red.
