import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';

Future<void> openBookUrl(BuildContext context, String url) async {
  final trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) {
    _showBookLinkFeedback(context, context.l10n.bookLinkUnavailable);
    return;
  }

  final uri = Uri.tryParse(trimmedUrl);
  if (uri == null || !uri.hasScheme) {
    _showBookLinkFeedback(context, context.l10n.bookLinkUnavailable);
    return;
  }

  try {
    final canOpen = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (!canOpen) {
      _showBookLinkFeedback(context, context.l10n.bookLinkOpenError);
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (!launched) {
      _showBookLinkFeedback(context, context.l10n.bookLinkOpenError);
    }
  } catch (_) {
    if (!context.mounted) return;
    _showBookLinkFeedback(context, context.l10n.bookLinkOpenError);
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
