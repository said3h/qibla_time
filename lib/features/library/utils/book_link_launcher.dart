import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openBookUrl(BuildContext context, String url) async {
  final trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) {
    _showBookLinkFeedback(context, 'Este enlace no está disponible.');
    return;
  }

  final uri = Uri.tryParse(trimmedUrl);
  if (uri == null || !uri.hasScheme) {
    _showBookLinkFeedback(context, 'Este enlace no está disponible.');
    return;
  }

  try {
    final canOpen = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (!canOpen) {
      _showBookLinkFeedback(context, 'No hemos podido abrir el enlace.');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (!launched) {
      _showBookLinkFeedback(context, 'No hemos podido abrir el enlace.');
    }
  } catch (_) {
    if (!context.mounted) return;
    _showBookLinkFeedback(context, 'No hemos podido abrir el enlace.');
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
