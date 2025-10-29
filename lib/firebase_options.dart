// File generated using dart pub run flutterfire_cli
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_5hIM-72kcyesnAVoIdkEVvEqriFRy5g',
    appId: '1:392284979137:android:f022e43596af4cf4457940',
    messagingSenderId: '392284979137',
    projectId: 'napolill-affirmation',
    storageBucket: 'napolill-affirmation.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgSQ3Jm83QGBTwstr9JalYxyiFW7bGrys',
    appId: '1:392284979137:ios:282cb9dabb9ccbc6457940',
    messagingSenderId: '392284979137',
    projectId: 'napolill-affirmation',
    storageBucket: 'napolill-affirmation.firebasestorage.app',
    iosBundleId: 'com.napolill.app',
    iosClientId: '392284979137-kql887618k232707dhdqovr17aslr8pp.apps.googleusercontent.com',
  );
}
