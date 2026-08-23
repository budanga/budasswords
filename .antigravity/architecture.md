# Arquitectura de Budasswords

## Estructura de Directorios

```text
lib/
├── app.dart                   # Widget raíz, configuración de tema, rutas y AppLifecycleListener
├── main.dart                  # Punto de entrada de la aplicación e init de Firebase
├── firebase_options.dart      # Opciones generadas de Firebase
├── core/
│   ├── constants/             # Constantes de configuración, tiempos, colores
│   ├── localization/          # Sistema de textos multilingüe (ES / EN)
│   └── utils/                 # Helpers (AppToast, ClipboardHelper)
├── crypto/                    # Cifrado AES-256-GCM, derivación Argon2id, utilidades
├── data/
│   ├── local/                 # Drift Database, tablas, DAOs (VaultDao)
│   └── remote/                # Cliente Firestore (FirebaseVaultApi)
├── domain/
│   └── models/                # Modelos de dominio (VaultEntry, UserSession)
├── providers/                 # Providers de Riverpod (auth, vault, locale, pinned, selection)
└── ui/
    ├── router/                # Definición de rutas GoRouter y redirección de auth
    ├── screens/               # Pantallas (auth, vault, entry, settings, splash)
    ├── theme/                 # Tema oscuro personalizado
    └── widgets/               # Componentes reutilizables por dominio
```

## Flujo de Datos y Criptografía

1. **Autenticación**:
   - Cuenta Firebase Auth para sincronización en la nube.
   - Derivación de clave local usando `Argon2id` con la contraseña maestra y un salt único almacenado en `FlutterSecureStorage` y metadata de Firestore.
   - Verificación de contraseña maestra mediante prueba cifrada (`createProof` / `verifyProof`).

2. **Almacenamiento y Sincronización**:
   - `VaultDao` recibe la instancia de `VaultCipher` tras desbloqueo exitoso.
   - Las lecturas/escrituras en SQLite (`Drift`) se cifran/descifran al vuelo.
   - Cambios locales se marcan como `isDirty = 1` y se suben a Firestore (`pushDirtyToRemote`).
   - Cambios remotos se escuchan en tiempo real (`watchChanges`) o se sincronizan en frío (`pullFromRemote`).

3. **Ciclo de Vida y Seguridad**:
   - `AppLifecycleListener` en `BudasswordsApp` bloquea la bóveda al pasar a segundo plano (`paused` / `hidden`).
   - `ClipboardHelper` limpia el contenido sensible a los 30s.
