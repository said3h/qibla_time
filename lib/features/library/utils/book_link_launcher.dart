import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/logger_service.dart';
import '../../../l10n/l10n.dart';

Future<void> openBookUrl(BuildContext context, String url) async {
  final trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) {
    AppLogger.warning('Book link unavailable: empty URL');
    _showBookLinkFeedback(context, context.l10n.bookLinkUnavailable);
    return;
  }

  final uri = Uri.tryParse(trimmedUrl);
  if (uri == null || !uri.hasScheme) {
    AppLogger.warning(
      'Book link unavailable: invalid URL="$trimmedUrl"',
    );
    _showBookLinkFeedback(context, context.l10n.bookLinkUnavailable);
    return;
  }

  bool canOpen = false;
  try {
    canOpen = await canLaunchUrl(uri);
    AppLogger.info(
      'Opening book link: url="$trimmedUrl", scheme="${uri.scheme}", canLaunchUrl=$canOpen',
    );
    if (!context.mounted) return;
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Book link canLaunchUrl failed: url="$trimmedUrl", scheme="${uri.scheme}"',
      error: error,
      stackTrace: stackTrace,
    );
    if (!context.mounted) return;
  }

  try {
    var launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && (uri.scheme == 'http' || uri.scheme == 'https')) {
      AppLogger.warning(
        'Book link external launch returned false, retrying platformDefault: url="$trimmedUrl"',
      );
      launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    }

    if (!context.mounted) return;
    if (!launched) {
      AppLogger.warning(
        'Book link launch returned false: url="$trimmedUrl", scheme="${uri.scheme}", canLaunchUrl=$canOpen',
      );
      _showBookLinkFeedback(context, context.l10n.bookNoCompatibleApp);
    }
  } catch (error, stackTrace) {
    AppLogger.error(
      'Book link launch failed: url="$trimmedUrl", scheme="${uri.scheme}", canLaunchUrl=$canOpen',
      error: error,
      stackTrace: stackTrace,
    );
    if (!context.mounted) return;
    _showBookLinkFeedback(context, context.l10n.bookNoCompatibleApp);
  }
}

void _showBookLinkFeedback(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ),
  );
}
