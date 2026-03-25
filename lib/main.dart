import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:soul_matcher/app/app.dart';
import 'package:soul_matcher/app/core/constants/admob_config.dart';
import 'package:soul_matcher/app/theme/theme_controller.dart';
import 'package:soul_matcher/firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (AdMobConfig.isSupportedPlatform) {
    final InitializationStatus initStatus = await MobileAds.instance
        .initialize();
    if (kDebugMode) {
      debugPrint(
        'AdMob initialized: ${initStatus.adapterStatuses.map((String key, AdapterStatus value) => MapEntry(key, value.state.name))}',
      );
    }
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  Get.put(ThemeController(), permanent: true);
  runApp(const SoulMatchApp());
}
