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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: "AIzaSyBGS2RAaZqOTFQxQUe84XUv5SF8AvQO_ps",
    authDomain: "liora-b71ba.firebaseapp.com",
    projectId: "liora-b71ba",
    storageBucket: "liora-b71ba.firebasestorage.app",
    messagingSenderId: "834011679989",
    appId: "1:834011679989:web:1bb4ad50084242bf9349bc",
    measurementId: "G-MK0RZP27SR"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBGS2RAaZqOTFQxQUe84XUv5SF8AvQO_ps",
    authDomain: "liora-b71ba.firebaseapp.com",
    projectId: "liora-b71ba",
    storageBucket: "liora-b71ba.firebasestorage.app",
    messagingSenderId: "834011679989",
    appId: "1:834011679989:android:1bb4ad50084242bf9349bc",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBGS2RAaZqOTFQxQUe84XUv5SF8AvQO_ps",
    authDomain: "liora-b71ba.firebaseapp.com",
    projectId: "liora-b71ba",
    storageBucket: "liora-b71ba.firebasestorage.app",
    messagingSenderId: "834011679989",
    appId: "1:834011679989:ios:1bb4ad50084242bf9349bc",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyBGS2RAaZqOTFQxQUe84XUv5SF8AvQO_ps",
    authDomain: "liora-b71ba.firebaseapp.com",
    projectId: "liora-b71ba",
    storageBucket: "liora-b71ba.firebasestorage.app",
    messagingSenderId: "834011679989",
    appId: "1:834011679989:macos:1bb4ad50084242bf9349bc",
  );
}
