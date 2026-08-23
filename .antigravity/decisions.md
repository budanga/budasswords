# Decisiones Técnicas

## 2026-08-23: Bloqueo Automático en Segundo Plano
- **Decisión**: Integrar `AppLifecycleListener` en el widget raíz `BudasswordsApp` para ejecutar `authProvider.notifier.lock()` cuando el estado pasa a `paused` o `hidden`.
- **Razón**: Mitigar el riesgo de exponer contraseñas en memoria al cambiar de app o suspender la ventana.
- **Trade-off**: El usuario debe ingresar nuevamente su contraseña maestra o biometría al reingresar a la app.

## 2026-08-23: Limpieza Centralizada del Portapapeles
- **Decisión**: Crear `ClipboardHelper.copySensitive` con temporizador de 30 segundos y validación del contenido antes de borrar.
- **Razón**: Evitar que contraseñas permanezcan accesibles indefinidamente para otras aplicaciones con acceso al portapapeles.
- **Trade-off**: Ninguno.

## 2026-08-23: Optimización de Sincronización en Desbloqueo
- **Decisión**: Cambiar la sincronización al desbloquear de `pushAllToRemote()` a `pushDirtyToRemote()`.
- **Razón**: Re-enviar todos los registros en cada inicio generaba llamadas redundantes e innecesarias a Firestore.
- **Trade-off**: Ninguno.

## 2026-08-23: Limpieza Granular de Sesión
- **Decisión**: En `signOut()`, eliminar específicamente las claves de credenciales (`kSaltKey`, `kProofBlobKey`, `kUserIdKey`, etc.) en lugar de `deleteAll()`.
- **Razón**: Preservar configuraciones globales del dispositivo como el tiempo de autolock.
- **Trade-off**: Ninguno.
