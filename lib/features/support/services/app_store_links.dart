import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class AppStoreLinks {
  const AppStoreLinks._();

  static const androidPackageId = 'com.qiblatime.mobile';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';
  static const playStoreAppUrl = 'market://details?id=$androidPackageId';

  static const appStoreSearchUrl =
      'https://apps.apple.com/search?term=Qibla%20Time&media=software';
  static const appStoreSearchAppUrl =
      'itms-apps://itunes.apple.com/search?term=Qibla%20Time&media=software';

  static Uri get rateUri {
    if (Platform.isAndroid) {
      return Uri.parse(playStoreAppUrl);
    }
    if (Platform.isIOS) {
      return Uri.parse(appStoreSearchAppUrl);
    }
    return Uri.parse(playStoreUrl);
  }

  static Uri get rateFallbackUri {
    if (Platform.isIOS) {
      return Uri.parse(appStoreSearchUrl);
    }
    return Uri.parse(playStoreUrl);
  }

  static String get shareUrl {
    if (Platform.isIOS) {
      return appStoreSearchUrl;
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
