enum AppLocale {
  es,
  en,
}

abstract class AppStrings {
  static AppStrings of(AppLocale locale) {
    switch (locale) {
      case AppLocale.en:
        return const _EnglishStrings();
      case AppLocale.es:
        return const _SpanishStrings();
    }
  }

  // Common
  String get appTitle;
  String get cancel;
  String get delete;
  String get save;
  String get create;
  String get edit;
  String get copiedToClipboard;
  String get error;
  String get retry;
  String get confirm;
  String get back;
  String get info;
  String get close;
  String get expandPanel;
  String get collapsePanel;

  // Categories
  String get allEntries;
  String get loginsAndAccounts;
  String get privateNotes;
  String get paymentCards;
  String get favorites;
  String get entryType;
  String get loginAccount;
  String get privateNote;
  String get paymentCard;

  // Auth - Login
  String get loadingVault;
  String get loginTitle;
  String get loginSubtitle;
  String get masterPassword;
  String get masterPasswordPrompt;
  String get unlockWithBiometrics;
  String get validateBiometricsFirst;
  String get openVault;
  String get incorrectPassword;
  String get biometricReason;
  String get invalidCredentials;
  String get emailNotConfirmed;
  String get setupFailed;
  String get noVaultFound;
  String get tooManyFailedAttempts;
  String lockoutCountdown(int seconds);

  // Auth - Setup
  String get welcomeBack;
  String get createYourVault;
  String get setupSubtitleCreate;
  String get setupSubtitleSignIn;
  String get emailLabel;
  String get emailHint;
  String get accountPasswordLabel;
  String get accountPasswordHelper;
  String get masterPasswordLabel;
  String get masterPasswordHelper;
  String get confirmMasterPasswordLabel;
  String get passwordsDoNotMatch;
  String get min8Chars;
  String get min12Chars;
  String get enterValidEmail;
  String get signInButton;
  String get createVaultButton;
  String get dontHaveVaultLink;
  String get alreadyHaveVaultLink;
  String get operationFailed;

  // Vault Screen
  String get searchPlaceholder;
  String get newEntry;
  String get quickGeneratorTitle;
  String get copy;
  String get generateNew;
  String get passwordCopied;
  String get emptyVaultTitle;
  String get emptyVaultSubtitle;
  String get noEntriesFoundTitle;
  String get noEntriesFoundSubtitle;
  String get desktopSelectEntryTitle;
  String get desktopSelectEntrySubtitle;
  String get websiteUrl;
  String get passwordOrSecret;
  String get localEncryptedNotice;
  String get pinToTop;
  String get unpin;
  String get addToFavorites;
  String get removeFromFavorites;
  String get deleteEntryConfirmTitle;
  String get deleteEntryConfirmContent;

  // Sync Badges
  String get cloudActive;
  String get syncing;
  String get localMode;
  String get tooltipCloudActive;
  String get tooltipSyncing;
  String get tooltipLocalMode;

  // Password Generator Sheet
  String get generateSecurePassword;
  String get generatePassword;
  String get passwordGeneratorTitle;
  String get length;
  String get uppercase;
  String get lowercase;
  String get numbers;
  String get symbols;
  String get copyPassword;
  String get usePassword;

  // Entry Form
  String get newEntryTitle;
  String get editEntryTitle;
  String get titleLabel;
  String get titleHintLogin;
  String get titleHintNote;
  String get titleHintCard;
  String get titleRequired;
  String get urlLabel;
  String get urlHint;
  String get noteContentLabel;
  String get cardContentLabel;
  String get passwordContentLabel;
  String get noteContentHint;
  String get passwordContentHint;
  String get contentRequired;
  String get saveChanges;
  String get saveEntry;
  String get show;
  String get hide;
  String get reveal;
  String copiedClearsIn(int seconds);

  // Entry Detail
  String get website;
  String get secret;
  String get createdOn;
  String get updatedOn;

  // Settings
  String get settingsTitle;
  String get languageSettingTitle;
  String get languageSettingSubtitle;
  String get autoLockTitle;
  String formatAutoLock(int minutes);
  String get lockNowTitle;
  String get lockNowSubtitle;
  String get importBitwardenTitle;
  String get importBitwardenSubtitle;
  String get exportVaultTitle;
  String get exportVaultSubtitle;
  String get signOutTitle;
  String get signOutSubtitle;
  String get signOutConfirmTitle;
  String get signOutConfirmContent;
  String get appFooter;

  // Import Screen
  String get importTitle;
  String get importHowTo;
  String get importStep1;
  String get importStep2;
  String get importStep3;
  String get importStep4;
  String get importWarning;
  String get importingProgress;
  String importSuccess(int count);
  String importSkipped(int count);
  String get importSelectFile;
  String get importCompleted;
  String get fileTooLarge;
  String get invalidBitwardenFormat;

  // Export Screen
  String get exportTitle;
  String get exportHowTo;
  String get exportWarning;
  String get exportSelectLocation;
  String get exportingProgress;
  String exportSuccess(int count);
  String get exportEmpty;

  // Admin Screen
  String get adminPanelTitle;
  String get adminPanelSubtitle;
  String get adminMetricsTitle;
  String get adminTotalUsers;
  String get adminTotalEntries;
  String get adminActive24h;
  String get adminActive7d;
  String get adminUsersDirectory;
  String get adminSearchUsersPlaceholder;
  String get adminUid;
  String get adminEmail;
  String get adminRole;
  String get adminRoleAdmin;
  String get adminRoleUser;
  String get adminCreatedAt;
  String get adminLastActive;
  String get adminEntries;
  String get adminUserDetailsTitle;
  String get adminDiagnostics;
  String get adminRunDiagnostics;
  String get adminLatency;
  String get adminConnectionHealthy;
  String get adminConnectionError;
  String get adminAccessDenied;
  String get adminNever;
  String get adminRefresh;
}

class _SpanishStrings implements AppStrings {
  const _SpanishStrings();

  @override String get appTitle => 'Budasswords';
  @override String get cancel => 'Cancelar';
  @override String get delete => 'Eliminar';
  @override String get save => 'Guardar';
  @override String get create => 'Crear';
  @override String get edit => 'Editar';
  @override String get copiedToClipboard => 'Copiado al portapapeles';
  @override String get error => 'Error';
  @override String get retry => 'Reintentar';
  @override String get confirm => 'Confirmar';
  @override String get back => 'Volver';
  @override String get info => 'Información';
  @override String get close => 'Cerrar';
  @override String get expandPanel => 'Expandir panel';
  @override String get collapsePanel => 'Minimizar panel';

  @override String get allEntries => 'Todas las entradas';
  @override String get loginsAndAccounts => 'Cuentas & logins';
  @override String get privateNotes => 'Notas privadas';
  @override String get paymentCards => 'Tarjetas & pagos';
  @override String get favorites => 'Favoritas';
  @override String get entryType => 'Tipo de entrada';
  @override String get loginAccount => 'Cuenta / login';
  @override String get privateNote => 'Nota privada';
  @override String get paymentCard => 'Tarjeta';

  @override String get loginTitle => 'Budasswords';
  @override String get loadingVault => 'Abriendo bóveda...';
  @override String get loginSubtitle => 'Ingresa tu contraseña maestra para abrir tu bóveda';
  @override String get masterPassword => 'Contraseña maestra';
  @override String get masterPasswordPrompt => 'Contraseña maestra';
  @override String get unlockWithBiometrics => 'Desbloquear con huella';
  @override String get validateBiometricsFirst => 'Valida tu huella primero...';
  @override String get openVault => 'Abrir bóveda';
  @override String get incorrectPassword => 'Contraseña maestra incorrecta';
  @override String get biometricReason => 'Desbloquear Budasswords';
  @override String get invalidCredentials => 'Correo o contraseña de cuenta incorrectos';
  @override String get emailNotConfirmed => 'Por favor confirma tu correo electrónico';
  @override String get setupFailed => 'Error al configurar la bóveda. Revisa tus datos.';
  @override String get noVaultFound => 'No se encontró una bóveda. Crea una primero.';
  @override String get tooManyFailedAttempts => 'Demasiados intentos fallidos. Bloqueado por 1 minuto.';
  @override String lockoutCountdown(int seconds) => 'Demasiados intentos. Espera ${seconds}s.';

  @override String get welcomeBack => 'Bienvenido de vuelta';
  @override String get createYourVault => 'Crea tu bóveda privada';
  @override String get setupSubtitleCreate => 'Un santuario seguro para todas tus cuentas y notas.';
  @override String get setupSubtitleSignIn => 'Inicia sesión para sincronizar tus cuentas.';
  @override String get emailLabel => 'Correo electrónico';
  @override String get emailHint => 'nombre@ejemplo.com';
  @override String get accountPasswordLabel => 'Contraseña de la cuenta';
  @override String get accountPasswordHelper => 'Para tu cuenta de Budasswords (sincronización). NO es la contraseña de tu correo.';
  @override String get masterPasswordLabel => 'Contraseña maestra (clave de tu bóveda)';
  @override String get masterPasswordHelper => 'Clave para cifrar tus datos en ESTE dispositivo. Solo tú la conoces y no se envía al servidor.';
  @override String get confirmMasterPasswordLabel => 'Confirmar contraseña maestra';
  @override String get passwordsDoNotMatch => 'Las contraseñas no coinciden';
  @override String get min8Chars => 'Mínimo 8 caracteres';
  @override String get min12Chars => 'Mínimo 12 caracteres recomendados';
  @override String get enterValidEmail => 'Ingresa un correo válido';
  @override String get signInButton => 'Iniciar sesión';
  @override String get createVaultButton => 'Crear bóveda';
  @override String get dontHaveVaultLink => '¿No tienes bóveda aún? Crear una';
  @override String get alreadyHaveVaultLink => '¿Ya tienes una bóveda? Iniciar sesión';
  @override String get operationFailed => 'La operación ha fallado';

  @override String get searchPlaceholder => 'Buscar por título, usuario o enlace...';
  @override String get newEntry => 'Nueva entrada';
  @override String get quickGeneratorTitle => 'Generador rápido';
  @override String get copy => 'Copiar';
  @override String get generateNew => 'Nueva';
  @override String get passwordCopied => 'Clave copiada';
  @override String get emptyVaultTitle => 'Tu bóveda está vacía';
  @override String get emptyVaultSubtitle => 'Crea tu primera entrada con el botón superior';
  @override String get noEntriesFoundTitle => 'No se encontraron entradas';
  @override String get noEntriesFoundSubtitle => 'Intenta con otro término o categoría';
  @override String get desktopSelectEntryTitle => 'Selecciona una entrada';
  @override String get desktopSelectEntrySubtitle => 'Elige un elemento de la lista para ver o editar sus detalles.';
  @override String get websiteUrl => 'Sitio web / enlace';
  @override String get passwordOrSecret => 'Contraseña / nota secreta';
  @override String get localEncryptedNotice => 'Guardado localmente y protegido con cifrado de cero conocimiento.';
  @override String get pinToTop => 'Añadir a favoritos';
  @override String get unpin => 'Quitar de favoritos';
  @override String get addToFavorites => 'Añadir a favoritos';
  @override String get removeFromFavorites => 'Quitar de favoritos';
  @override String get deleteEntryConfirmTitle => '¿Eliminar entrada?';
  @override String get deleteEntryConfirmContent => 'Esta acción no se puede deshacer.';

  @override String get cloudActive => 'Nube activa';
  @override String get syncing => 'Sincronizando...';
  @override String get localMode => 'Modo local';
  @override String get tooltipCloudActive => 'Sincronizado con la nube de forma segura';
  @override String get tooltipSyncing => 'Sincronizando cambios pendientes...';
  @override String get tooltipLocalMode => 'Modo local (sin conexión)';

  @override String get generateSecurePassword => 'Generar contraseña segura';
  @override String get generatePassword => 'Generar contraseña';
  @override String get passwordGeneratorTitle => 'Generador de contraseñas';
  @override String get length => 'Longitud';
  @override String get uppercase => 'Mayúsculas';
  @override String get lowercase => 'Minúsculas';
  @override String get numbers => 'Números';
  @override String get symbols => 'Símbolos';
  @override String get copyPassword => 'Copiar contraseña';
  @override String get usePassword => 'Usar contraseña';

  @override String get newEntryTitle => 'Nueva entrada';
  @override String get editEntryTitle => 'Editar entrada';
  @override String get titleLabel => 'Nombre / título';
  @override String get titleHintLogin => 'Ej: GitHub, Correo de trabajo, Wi-Fi Casa...';
  @override String get titleHintNote => 'Ej: Ideas para el proyecto, Diario, Lista...';
  @override String get titleHintCard => 'Ej: Visa Banco, Débito Personal...';
  @override String get titleRequired => 'El título es obligatorio';
  @override String get urlLabel => 'Sitio web / enlace (opcional)';
  @override String get urlHint => 'https://ejemplo.com';
  @override String get noteContentLabel => 'Contenido de la nota privada';
  @override String get cardContentLabel => 'Datos de la tarjeta (número, titular, CVV)';
  @override String get passwordContentLabel => 'Contraseña o contenido secreto';
  @override String get noteContentHint => 'Escribe libremente tus notas o reflexiones privadas...';
  @override String get passwordContentHint => 'Escribe tu contraseña o texto privado...';
  @override String get contentRequired => 'El contenido no puede estar vacío';
  @override String get saveChanges => 'Guardar cambios';
  @override String get saveEntry => 'Guardar entrada';
  @override String get show => 'Mostrar';
  @override String get hide => 'Ocultar';
  @override String get reveal => 'Revelar';
  @override String copiedClearsIn(int seconds) => '¡Copiado! Se borra en ${seconds}s';

  @override String get website => 'Sitio web / enlace';
  @override String get secret => 'Contraseña o nota secreta';
  @override String get createdOn => 'Creado el';
  @override String get updatedOn => 'Modificado el';

  @override String get settingsTitle => 'Ajustes';
  @override String get languageSettingTitle => 'Idioma / Language';
  @override String get languageSettingSubtitle => 'Español';
  @override String get autoLockTitle => 'Bloqueo automático por inactividad';
  @override String formatAutoLock(int minutes) {
    if (minutes < 60) return '$minutes minutos';
    if (minutes == 60) return '1 hora';
    if (minutes == 90) return '1.5 horas';
    if (minutes == 120) return '2 horas';
    if (minutes == 180) return '3 horas';
    return '$minutes min';
  }
  @override String get lockNowTitle => 'Bloquear bóveda ahora';
  @override String get lockNowSubtitle => 'Requerirá tu contraseña maestra para reabrir';
  @override String get importBitwardenTitle => 'Importar desde Bitwarden';
  @override String get importBitwardenSubtitle => 'Migra tus contraseñas y notas mediante archivo JSON';
  @override String get exportVaultTitle => 'Exportar bóveda';
  @override String get exportVaultSubtitle => 'Copia de seguridad en archivo JSON sin cifrar';
  @override String get signOutTitle => 'Cerrar sesión';
  @override String get signOutSubtitle => 'Borra las claves en memoria y datos locales';
  @override String get signOutConfirmTitle => '¿Cerrar sesión?';
  @override String get signOutConfirmContent => 'Esto limpiará los datos de la sesión local. Tu bóveda cifrada permanece segura en la nube.';
  @override String get appFooter => 'Budasswords · El Cuaderno Silencioso\nCifrado integral de cero conocimiento';

  @override String get importTitle => 'Importar desde Bitwarden';
  @override String get importHowTo => 'Cómo exportar desde Bitwarden';
  @override String get importStep1 => 'Abre Bitwarden en tu navegador o aplicación.';
  @override String get importStep2 => 'Ve a Herramientas → Exportar Bóveda.';
  @override String get importStep3 => 'Selecciona el formato JSON (sin cifrar).';
  @override String get importStep4 => 'Guarda el archivo y elígelo aquí.';
  @override String get importWarning => '⚠ El archivo JSON contiene tus contraseñas en texto claro. Recuerda borrarlo al terminar.';
  @override String get importingProgress => 'Importando y cifrando entradas...';
  @override String importSuccess(int count) => '$count entradas importadas con éxito';
  @override String importSkipped(int count) => '$count entradas no pudieron ser procesadas.';
  @override String get importSelectFile => 'Seleccionar archivo JSON';
  @override String get importCompleted => 'Importación completada';
  @override String get fileTooLarge => 'El archivo es demasiado grande (máximo 10MB).';
  @override String get invalidBitwardenFormat => 'Formato de archivo Bitwarden inválido.';

  // Export Screen
  @override String get exportTitle => 'Exportar bóveda';
  @override String get exportHowTo => 'Exportación de seguridad';
  @override String get exportWarning => '⚠ El archivo exportado contiene tus contraseñas y notas en texto claro. Guárdalo únicamente en ubicaciones de total confianza.';
  @override String get exportSelectLocation => 'Guardar archivo de respaldo (JSON)';
  @override String get exportingProgress => 'Exportando y generando archivo...';
  @override String exportSuccess(int count) => 'Bóveda exportada exitosamente ($count entradas)';
  @override String get exportEmpty => 'No hay entradas en la bóveda para exportar.';

  // Admin Screen
  @override String get adminPanelTitle => 'Panel de administración';
  @override String get adminPanelSubtitle => 'Métricas globales y directorio de usuarios';
  @override String get adminMetricsTitle => 'Métricas globales';
  @override String get adminTotalUsers => 'Total de usuarios';
  @override String get adminTotalEntries => 'Entradas en la nube';
  @override String get adminActive24h => 'Activos (24h)';
  @override String get adminActive7d => 'Activos (7d)';
  @override String get adminUsersDirectory => 'Directorio de usuarios';
  @override String get adminSearchUsersPlaceholder => 'Buscar por correo o UID...';
  @override String get adminUid => 'UID';
  @override String get adminEmail => 'Correo electrónico';
  @override String get adminRole => 'Rol';
  @override String get adminRoleAdmin => 'Administrador';
  @override String get adminRoleUser => 'Usuario';
  @override String get adminCreatedAt => 'Fecha de registro';
  @override String get adminLastActive => 'Última actividad';
  @override String get adminEntries => 'Entradas';
  @override String get adminUserDetailsTitle => 'Inspección de usuario';
  @override String get adminDiagnostics => 'Diagnóstico de Firestore';
  @override String get adminRunDiagnostics => 'Probar latencia y conexión';
  @override String get adminLatency => 'Latencia';
  @override String get adminConnectionHealthy => 'Conexión operativa';
  @override String get adminConnectionError => 'Error de conexión';
  @override String get adminAccessDenied => 'Acceso restringido únicamente al administrador';
  @override String get adminNever => 'Nunca';
  @override String get adminRefresh => 'Actualizar';
}

class _EnglishStrings implements AppStrings {
  const _EnglishStrings();

  @override String get appTitle => 'Budasswords';
  @override String get cancel => 'Cancel';
  @override String get delete => 'Delete';
  @override String get save => 'Save';
  @override String get create => 'Create';
  @override String get edit => 'Edit';
  @override String get copiedToClipboard => 'Copied to clipboard';
  @override String get error => 'Error';
  @override String get retry => 'Retry';
  @override String get confirm => 'Confirm';
  @override String get back => 'Back';
  @override String get info => 'Information';
  @override String get close => 'Close';
  @override String get expandPanel => 'Expand panel';
  @override String get collapsePanel => 'Collapse panel';

  @override String get allEntries => 'All Entries';
  @override String get loginsAndAccounts => 'Logins & Accounts';
  @override String get privateNotes => 'Private Notes';
  @override String get paymentCards => 'Payment Cards';
  @override String get favorites => 'Favorites';
  @override String get entryType => 'ENTRY TYPE';
  @override String get loginAccount => 'Login / Account';
  @override String get privateNote => 'Private Note';
  @override String get paymentCard => 'Card';

  @override String get loginTitle => 'Budasswords';
  @override String get loadingVault => 'Loading vault...';
  @override String get loginSubtitle => 'Enter your master password to unlock your vault';
  @override String get masterPassword => 'Master password';
  @override String get masterPasswordPrompt => 'Master password';
  @override String get unlockWithBiometrics => 'Unlock with Fingerprint';
  @override String get validateBiometricsFirst => 'Validate biometrics first...';
  @override String get openVault => 'Open Vault';
  @override String get incorrectPassword => 'Incorrect master password';
  @override String get biometricReason => 'Unlock Budasswords';
  @override String get invalidCredentials => 'Invalid email or password';
  @override String get emailNotConfirmed => 'Please confirm your email address';
  @override String get setupFailed => 'Setup failed. Please check your details.';
  @override String get noVaultFound => 'No vault found. Please create one first.';
  @override String get tooManyFailedAttempts => 'Too many failed attempts. Locked out for 1 minute.';
  @override String lockoutCountdown(int seconds) => 'Too many attempts. Try again in ${seconds}s.';

  @override String get welcomeBack => 'Welcome back';
  @override String get createYourVault => 'Create your Private Vault';
  @override String get setupSubtitleCreate => 'A peaceful sanctuary for all your accounts and private notes.';
  @override String get setupSubtitleSignIn => 'Sign in to sync your vault across devices.';
  @override String get emailLabel => 'Email address';
  @override String get emailHint => 'name@example.com';
  @override String get accountPasswordLabel => 'Account password';
  @override String get accountPasswordHelper => 'For your Budasswords account (sync). NOT your email provider password.';
  @override String get masterPasswordLabel => 'Master password (vault key)';
  @override String get masterPasswordHelper => 'Key to encrypt your data on THIS device. Only you know it; never sent to server.';
  @override String get confirmMasterPasswordLabel => 'Confirm master password';
  @override String get passwordsDoNotMatch => 'Passwords do not match';
  @override String get min8Chars => 'Minimum 8 characters';
  @override String get min12Chars => 'Minimum 12 characters recommended';
  @override String get enterValidEmail => 'Enter a valid email address';
  @override String get signInButton => 'Sign In';
  @override String get createVaultButton => 'Create Vault';
  @override String get dontHaveVaultLink => "Don't have a vault yet? Create one";
  @override String get alreadyHaveVaultLink => 'Already have a vault? Sign in';
  @override String get operationFailed => 'Operation failed';

  @override String get searchPlaceholder => 'Search by title, username, or URL...';
  @override String get newEntry => 'New entry';
  @override String get quickGeneratorTitle => 'QUICK GENERATOR';
  @override String get copy => 'Copy';
  @override String get generateNew => 'New';
  @override String get passwordCopied => 'Password copied';
  @override String get emptyVaultTitle => 'Your vault is empty';
  @override String get emptyVaultSubtitle => 'Create your first entry using the button above';
  @override String get noEntriesFoundTitle => 'No entries found';
  @override String get noEntriesFoundSubtitle => 'Try another search term or filter';
  @override String get desktopSelectEntryTitle => 'Select an entry';
  @override String get desktopSelectEntrySubtitle => 'Choose an item from the list to view or edit its details.';
  @override String get websiteUrl => 'WEBSITE / URL';
  @override String get passwordOrSecret => 'PASSWORD / PRIVATE NOTE';
  @override String get localEncryptedNotice => 'Stored locally and protected with zero-knowledge encryption.';
  @override String get pinToTop => 'Add to favorites';
  @override String get unpin => 'Remove from favorites';
  @override String get addToFavorites => 'Add to favorites';
  @override String get removeFromFavorites => 'Remove from favorites';
  @override String get deleteEntryConfirmTitle => 'Delete entry?';
  @override String get deleteEntryConfirmContent => 'This action cannot be undone.';

  @override String get cloudActive => 'Cloud active';
  @override String get syncing => 'Syncing...';
  @override String get localMode => 'Local mode';
  @override String get tooltipCloudActive => 'Securely synced with the cloud';
  @override String get tooltipSyncing => 'Syncing pending changes...';
  @override String get tooltipLocalMode => 'Local mode (offline)';

  @override String get generateSecurePassword => 'Generate Secure Password';
  @override String get generatePassword => 'Generate password';
  @override String get passwordGeneratorTitle => 'Password Generator';
  @override String get length => 'Length';
  @override String get uppercase => 'Uppercase';
  @override String get lowercase => 'Lowercase';
  @override String get numbers => 'Numbers';
  @override String get symbols => 'Symbols';
  @override String get copyPassword => 'Copy Password';
  @override String get usePassword => 'Use Password';

  @override String get newEntryTitle => 'New Entry';
  @override String get editEntryTitle => 'Edit Entry';
  @override String get titleLabel => 'Name / Title';
  @override String get titleHintLogin => 'e.g. GitHub, Work email, Home Wi-Fi...';
  @override String get titleHintNote => 'e.g. Project ideas, Journal, To-do...';
  @override String get titleHintCard => 'e.g. Bank Visa, Personal Debit...';
  @override String get titleRequired => 'Title is required';
  @override String get urlLabel => 'Website / URL (optional)';
  @override String get urlHint => 'https://example.com';
  @override String get noteContentLabel => 'Private note content';
  @override String get cardContentLabel => 'Card details (Number, Holder, CVV)';
  @override String get passwordContentLabel => 'Password or Secret Content';
  @override String get noteContentHint => 'Freely write your private thoughts or notes...';
  @override String get passwordContentHint => 'Write your password or secret text...';
  @override String get contentRequired => 'Content cannot be empty';
  @override String get saveChanges => 'Save Changes';
  @override String get saveEntry => 'Save Entry';
  @override String get show => 'Show';
  @override String get hide => 'Hide';
  @override String get reveal => 'Reveal';
  @override String copiedClearsIn(int seconds) => 'Copied! Clears in ${seconds}s';

  @override String get website => 'Website / URL';
  @override String get secret => 'Password or Private Note';
  @override String get createdOn => 'Created on';
  @override String get updatedOn => 'Updated on';

  @override String get settingsTitle => 'Settings';
  @override String get languageSettingTitle => 'Language / Idioma';
  @override String get languageSettingSubtitle => 'English';
  @override String get autoLockTitle => 'Auto-lock on inactivity';
  @override String formatAutoLock(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    if (minutes == 60) return '1 hour';
    if (minutes == 90) return '1.5 hours';
    if (minutes == 120) return '2 hours';
    if (minutes == 180) return '3 hours';
    return '$minutes min';
  }
  @override String get lockNowTitle => 'Lock vault now';
  @override String get lockNowSubtitle => 'Will require your master password to reopen';
  @override String get importBitwardenTitle => 'Import from Bitwarden';
  @override String get importBitwardenSubtitle => 'Migrate passwords and notes via JSON export';
  @override String get exportVaultTitle => 'Export Vault';
  @override String get exportVaultSubtitle => 'Create an unencrypted JSON backup file';
  @override String get signOutTitle => 'Sign out';
  @override String get signOutSubtitle => 'Clears in-memory keys and local cache';
  @override String get signOutConfirmTitle => 'Sign out?';
  @override String get signOutConfirmContent => 'This will clear local session data. Your encrypted vault remains safe in the cloud.';
  @override String get appFooter => 'Budasswords · The Quiet Archive\nEnd-to-end zero-knowledge encryption';

  @override String get importTitle => 'Import from Bitwarden';
  @override String get importHowTo => 'How to export from Bitwarden';
  @override String get importStep1 => 'Open Bitwarden in your browser or desktop app.';
  @override String get importStep2 => 'Go to Tools → Export Vault.';
  @override String get importStep3 => 'Select JSON format (unencrypted).';
  @override String get importStep4 => 'Save the file and select it here.';
  @override String get importWarning => '⚠ The JSON file contains passwords in plain text. Delete it when finished.';
  @override String get importingProgress => 'Importing and encrypting entries...';
  @override String importSuccess(int count) => '$count entries successfully imported';
  @override String importSkipped(int count) => '$count entries could not be processed.';
  @override String get importSelectFile => 'Select JSON file';
  @override String get importCompleted => 'Import completed';
  @override String get fileTooLarge => 'The file is too large (maximum 10MB).';
  @override String get invalidBitwardenFormat => 'Invalid Bitwarden JSON export format.';

  // Export Screen
  @override String get exportTitle => 'Export Vault';
  @override String get exportHowTo => 'Backup export';
  @override String get exportWarning => '⚠ The exported file contains all passwords and notes in plain text. Keep it in a strictly secure and trusted location.';
  @override String get exportSelectLocation => 'Save backup file (JSON)';
  @override String get exportingProgress => 'Exporting and generating file...';
  @override String exportSuccess(int count) => 'Vault successfully exported ($count entries)';
  @override String get exportEmpty => 'No vault entries to export.';

  // Admin Screen
  @override String get adminPanelTitle => 'Admin Panel';
  @override String get adminPanelSubtitle => 'Global metrics and user directory';
  @override String get adminMetricsTitle => 'Global Metrics';
  @override String get adminTotalUsers => 'Total Users';
  @override String get adminTotalEntries => 'Cloud Entries';
  @override String get adminActive24h => 'Active (24h)';
  @override String get adminActive7d => 'Active (7d)';
  @override String get adminUsersDirectory => 'User Directory';
  @override String get adminSearchUsersPlaceholder => 'Search by email or UID...';
  @override String get adminUid => 'UID';
  @override String get adminEmail => 'Email';
  @override String get adminRole => 'Role';
  @override String get adminRoleAdmin => 'Admin';
  @override String get adminRoleUser => 'User';
  @override String get adminCreatedAt => 'Registered';
  @override String get adminLastActive => 'Last Active';
  @override String get adminEntries => 'Entries';
  @override String get adminUserDetailsTitle => 'User Inspection';
  @override String get adminDiagnostics => 'Firestore Diagnostics';
  @override String get adminRunDiagnostics => 'Test Latency & Connection';
  @override String get adminLatency => 'Latency';
  @override String get adminConnectionHealthy => 'Connection Healthy';
  @override String get adminConnectionError => 'Connection Error';
  @override String get adminAccessDenied => 'Access restricted to administrators only';
  @override String get adminNever => 'Never';
  @override String get adminRefresh => 'Refresh';
}
