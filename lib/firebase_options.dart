// Configuración de Firebase tomada de google-services.json (proyecto lapticon-eba31).
// Al pasar estas opciones a Firebase.initializeApp no hace falta el plugin
// de Gradle "com.google.gms.google-services".
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase no está configurado para web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Solo Android está configurado. Para iOS ejecuta "flutterfire configure".',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAuh64b_I2OtC7KYuubCVx9plEe2pojp2M',
    appId: '1:919252353880:android:3d32e8039ee5faf55d5b2d', // com.lapticon.app
    messagingSenderId: '919252353880',
    projectId: 'lapticon-eba31',
    storageBucket: 'lapticon-eba31.firebasestorage.app',
  );
}
