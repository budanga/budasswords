import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated file or configured for Budasswords.
/// You can update these values with your actual Firebase project credentials
/// or run `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyASFV1VEaHv9TObDuDEiOSClqYp5bYcz3w',
    appId: '1:716579474362:web:631b8e04b46f8fd5afeb83',
    messagingSenderId: '716579474362',
    projectId: 'budasswords',
    authDomain: 'budasswords.firebaseapp.com',
    storageBucket: 'budasswords.firebasestorage.app',
    measurementId: 'G-P12XBS1ZNZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDaODadPFG1jRQLSBeF6uDMkjGOcfKTAzo',
    appId: '1:716579474362:android:6d59035838469bd8afeb83',
    messagingSenderId: '716579474362',
    projectId: 'budasswords',
    storageBucket: 'budasswords.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY',
        defaultValue: 'AIzaSyDemoDummyKeyForBudasswordsIos12345'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID',
        defaultValue: '1:1234567890:ios:abcdef123456'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '1234567890'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID',
        defaultValue: 'budasswords-vault'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET',
        defaultValue: 'budasswords-vault.appspot.com'),
    iosBundleId: 'com.budasswords.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_MACOS_API_KEY',
        defaultValue: 'AIzaSyDemoDummyKeyForBudasswordsMac12345'),
    appId: String.fromEnvironment('FIREBASE_MACOS_APP_ID',
        defaultValue: '1:1234567890:ios:abcdef123456'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '1234567890'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID',
        defaultValue: 'budasswords-vault'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET',
        defaultValue: 'budasswords-vault.appspot.com'),
    iosBundleId: 'com.budasswords.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyASFV1VEaHv9TObDuDEiOSClqYp5bYcz3w',
    appId: '1:716579474362:web:631b8e04b46f8fd5afeb83',
    messagingSenderId: '716579474362',
    projectId: 'budasswords',
    authDomain: 'budasswords.firebaseapp.com',
    storageBucket: 'budasswords.firebasestorage.app',
    measurementId: 'G-P12XBS1ZNZ',
  );
}
