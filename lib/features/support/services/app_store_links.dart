import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class AppStoreLinks {
  const AppStoreLinks._();

  static const androidPackageId = 'com.qiblatime.mobile';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';
  static const playStoreAppUrl = 'market://details?id=$androidPackageId';

  static const appStoreUrl =
      'https://apps.apple.com/es/app/qibla-time/id6771987364';
  static const appStoreAppUrl = 'itms-apps://itunes.apple.com/app/id6771987364';

  static Uri get rateUri {
    if (Platform.isAndroid) {
      return Uri.parse(playStoreAppUrl);
    }
    if (Platform.isIOS) {
      return Uri.parse(appStoreAppUrl);
    }
    return Uri.parse(playStoreUrl);
  }

  static Uri get rateFallbackUri {
    if (Platform.isIOS) {
      return Uri.parse(appStoreUrl);
    }
    return Uri.parse(playStoreUrl);
  }

  static String get shareUrl {
    if (Platform.isIOS) {
      return appStoreUrl;
    }
    return playStoreUrl;
  }

  static Future<void> openStoreListing() async {
    final uri = rateUri;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(rateFallbackUri, mode: LaunchMode.externalApplication);
  }
}
