// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlnJLGtJwQtNnyyXCXe-UK-ilbYqwouuU',
    appId: '1:502368898550:web:0d3440170747f8e3af4bd7',
    messagingSenderId: '502368898550',
    projectId: 'ea-fc-tournament-manager',
    authDomain: 'ea-fc-tournament-manager.firebaseapp.com',
    databaseURL: 'https://ea-fc-tournament-manager-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'ea-fc-tournament-manager.appspot.com',
    measurementId: 'G-6M27VMTL87',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsAQXIf27hqEZPg9Lgk3gQg6FFUNprKuY',
    appId: '1:502368898550:android:5a5c45b4564dbfe8af4bd7',
    messagingSenderId: '502368898550',
    projectId: 'ea-fc-tournament-manager',
    databaseURL: 'https://ea-fc-tournament-manager-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'ea-fc-tournament-manager.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCL22xMRi-liWCsDmrtFgb12379lOKGQy8',
    appId: '1:502368898550:ios:d15478e6bfedfd7caf4bd7',
    messagingSenderId: '502368898550',
    projectId: 'ea-fc-tournament-manager',
    databaseURL: 'https://ea-fc-tournament-manager-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'ea-fc-tournament-manager.appspot.com',
    iosBundleId: 'com.example.eaFcTournamentManager',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCL22xMRi-liWCsDmrtFgb12379lOKGQy8',
    appId: '1:502368898550:ios:d15478e6bfedfd7caf4bd7',
    messagingSenderId: '502368898550',
    projectId: 'ea-fc-tournament-manager',
    databaseURL: 'https://ea-fc-tournament-manager-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'ea-fc-tournament-manager.appspot.com',
    iosBundleId: 'com.example.eaFcTournamentManager',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBlnJLGtJwQtNnyyXCXe-UK-ilbYqwouuU',
    appId: '1:502368898550:web:124722cf24838b69af4bd7',
    messagingSenderId: '502368898550',
    projectId: 'ea-fc-tournament-manager',
    authDomain: 'ea-fc-tournament-manager.firebaseapp.com',
    databaseURL: 'https://ea-fc-tournament-manager-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'ea-fc-tournament-manager.appspot.com',
    measurementId: 'G-PERKLEE8DE',
  );
}
