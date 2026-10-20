// File generated with live Firebase options for project SmartNutri (smartnutri-e8c4c).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCevyU2tTGYcCN9jHCmTPfaaNs6OhBPFHE',
    appId: '1:962279183938:web:dd0970099e1751d837bfdb',
    messagingSenderId: '962279183938',
    projectId: 'smartnutri-e8c4c',
    authDomain: 'smartnutri-e8c4c.firebaseapp.com',
    storageBucket: 'smartnutri-e8c4c.firebasestorage.app',
    measurementId: 'G-XG2FNBNSEE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCevyU2tTGYcCN9jHCmTPfaaNs6OhBPFHE',
    appId: '1:962279183938:android:dd0970099e1751d837bfdb',
    messagingSenderId: '962279183938',
    projectId: 'smartnutri-e8c4c',
    storageBucket: 'smartnutri-e8c4c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCevyU2tTGYcCN9jHCmTPfaaNs6OhBPFHE',
    appId: '1:962279183938:ios:dd0970099e1751d837bfdb',
    messagingSenderId: '962279183938',
    projectId: 'smartnutri-e8c4c',
    storageBucket: 'smartnutri-e8c4c.firebasestorage.app',
    iosBundleId: 'com.smartnutri.mobile',
  );
}
