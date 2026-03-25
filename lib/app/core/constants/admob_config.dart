import 'package:flutter/foundation.dart';

class AdMobConfig {
  AdMobConfig._();

  static const String androidAppId = 'ca-app-pub-8470795835714930~5464178961';
  static const String androidBannerAdUnitId =
      'ca-app-pub-8470795835714930/8232844936';

  // Replace these with your iOS AdMob IDs when you create them.
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static bool get isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String get bannerAdUnitId {
    if (!isSupportedPlatform) {
      return '';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return kDebugMode ? _androidTestBannerAdUnitId : androidBannerAdUnitId;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return kDebugMode ? _iosTestBannerAdUnitId : iosBannerAdUnitId;
    }

    return '';
  }
}
