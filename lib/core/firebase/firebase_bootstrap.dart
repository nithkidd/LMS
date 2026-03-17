import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:trellis/firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<bool> initialize() async {
    if (Firebase.apps.isNotEmpty) return true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } on UnsupportedError catch (error) {
      debugPrint(
        'Skipping Firebase initialization on this platform: ${error.message}',
      );
      return false;
    } on FirebaseException catch (error) {
      debugPrint(
        'Skipping Firebase initialization because setup is incomplete: '
        '${error.message ?? error.code}',
      );
      return false;
    }
  }
}
