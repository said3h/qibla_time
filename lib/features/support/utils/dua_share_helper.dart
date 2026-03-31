import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/dua_model.dart';
import '../services/dua_share_service.dart';
import '../widgets/dua_share_preview_sheet.dart';

Future<void> shareDua(BuildContext context, Dua dua) {
  return showDuaSharePreviewSheet(
    context: context,
    dua: dua,
    shareService: const DuaShareService(),
    tokens: QiblaThemes.current,
  );
}
