// Generated Firebase configuration for ThinkFlow
// Project: thinkflow-168b3
// Web App: thinkflow (1:131650404642:web:848016c454cfb8f1afe57b)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Only web is configured for now
    throw UnsupportedError(
      'DefaultFirebaseOptions is not configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwaZwokk5KNastWsT8xDR-_n1woOBZ47c',
    appId: '1:131650404642:web:848016c454cfb8f1afe57b',
    messagingSenderId: '131650404642',
    projectId: 'thinkflow-168b3',
    authDomain: 'thinkflow-168b3.firebaseapp.com',
    storageBucket: 'thinkflow-168b3.firebasestorage.app',
    measurementId: 'G-K4QCZF2EGJ',
  );
}
