import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

Future<void> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') return;
    rethrow;
  }
}
