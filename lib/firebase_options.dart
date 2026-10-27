import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Public client configuration only; access is enforced by firestore.rules.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('BookShelf supports Android and web.');
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCcQoGzB8pjgvw7wyfGySazrXxqIR1cp4A',
    appId: '1:958806753776:web:1acb90b62d9b3209391d35',
    messagingSenderId: '958806753776',
    projectId: 'bookshelf-qe190017',
    authDomain: 'bookshelf-qe190017.firebaseapp.com',
    storageBucket: 'bookshelf-qe190017.firebasestorage.app',
  );
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCcQoGzB8pjgvw7wyfGySazrXxqIR1cp4A',
    appId: '1:958806753776:android:73782e022324c555391d35',
    messagingSenderId: '958806753776',
    projectId: 'bookshelf-qe190017',
    storageBucket: 'bookshelf-qe190017.firebasestorage.app',
  );
}
