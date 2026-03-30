import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/dua_model.dart';

Future<void> shareDua(BuildContext context, Dua dua) async {
  final sections = <String>[
    dua.title.trim(),
    if (dua.arabicText.trim().isNotEmpty) dua.arabicText.trim(),
    if (dua.transliteration.trim().isNotEmpty) dua.transliteration.trim(),
    if (dua.translation.trim().isNotEmpty) dua.translation.trim(),
    if ((dua.reference ?? '').trim().isNotEmpty)
      'Referencia: ${(dua.reference ?? '').trim()}',
    if ((dua.source ?? '').trim().isNotEmpty)
      'Fuente: ${(dua.source ?? '').trim()}',
    'App: Qibla Time',
  ];

  try {
    await Share.share(
      sections.join('\n\n'),
      subject: dua.title.trim().isEmpty ? 'Dua' : dua.title.trim(),
    );
  } catch (_) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('No se pudo compartir la dua'),
      ),
    );
  }
}
