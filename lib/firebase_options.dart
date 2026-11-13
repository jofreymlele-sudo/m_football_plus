// File generated for FlutterFire support in M Football Plus.
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

  // Web configuration (Usanidi halisi wa Firebase Web)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAT_VhQugNjpqMjbcxRpqGm15pDoFQwjW4',
    appId: '1:435783685908:web:1f476d3695abcde3e39401',
    messagingSenderId: '435783685908',
    projectId: 'mlele-financial-tracker',
    authDomain: 'mlele-financial-tracker.firebaseapp.com',
    storageBucket: 'mlele-financial-tracker.firebasestorage.app',
  );

  // Android configuration (Kutoka kwenye google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOKjpcacAmqrjLqzyax8GZflYi_vH0tqQ',
    appId: '1:435783685908:android:1f476d3695abcde3e39401',
    messagingSenderId: '435783685908',
    projectId: 'mlele-financial-tracker',
    storageBucket: 'mlele-financial-tracker.firebasestorage.app',
  );

  // iOS configuration (Kutoka kwenye GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyANYEy7LIK5ieC4iZFL8PqnfuCXkG0BZXw',
    appId: '1:435783685908:ios:3b37d9acfd235b52e39401',
    messagingSenderId: '435783685908',
    projectId: 'mlele-financial-tracker',
    storageBucket: 'mlele-financial-tracker.firebasestorage.app',
    iosBundleId: 'com.mlele.mfootballplus',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '435783685908',
    projectId: 'mlele-financial-tracker',
    storageBucket: 'mlele-financial-tracker.firebasestorage.app',
    iosBundleId: 'com.mlele.mfootballplus',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAT_VhQugNjpqMjbcxRpqGm15pDoFQwjW4',
    appId: '1:435783685908:web:1f476d3695abcde3e39401',
    messagingSenderId: '435783685908',
    projectId: 'mlele-financial-tracker',
    authDomain: 'mlele-financial-tracker.firebaseapp.com',
    storageBucket: 'mlele-financial-tracker.firebasestorage.app',
  );
}
