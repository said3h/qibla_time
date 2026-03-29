import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../hadith_share/models/hadith_share_data.dart';
import '../../hadith_share/models/hadith_share_theme.dart';
import '../../hadith_share/services/hadith_share_image_service.dart';
import '../models/hadith.dart';

final hadithShareServiceProvider = Provider<HadithShareService>((ref) {
  return HadithShareService();
});

/// Servicio para compartir hadices como texto o imagen
class HadithShareService {
  /// Construye el texto para compartir
  String buildShareText(Hadith hadith) {
    final arabic = hadith.arabic.trim();
    final translation = hadith.translation.trim();
    final reference = hadith.reference.trim();
    final grade = hadith.grade.trim();

    final sections = <String>[
      if (arabic.isNotEmpty) arabic,
      if (translation.isNotEmpty) translation,
      if (reference.isNotEmpty) 'â€” $reference',
      if (grade.isNotEmpty) 'Grado: $grade',
      '',
      'Compartido desde Qibla Time',
    ];

    return sections.join('\n');
  }

  /// Comparte el hadiz como texto
  Future<void> shareHadithAsText(Hadith hadith) async {
    await Share.share(
      buildShareText(hadith),
      subject: 'Hadiz del dÃ­a - Qibla Time',
    );
  }

  /// Comparte el hadiz como imagen con diseÃ±o mejorado
  Future<void> shareHadithAsImage(
    Hadith hadith,
    QiblaTokens tokens, {
    bool withDecoration = true,
  }) async {
    try {
      final file = await HadithShareImageService.savePng(
        data: HadithShareData(
          arabicText: hadith.arabic,
          translation: hadith.translation,
          reference: hadith.reference,
          branding: 'Qibla Time',
        ),
        theme: HadithShareThemeData.fromTokens(
          tokens,
          transparentBackground: !withDecoration,
        ),
        transparentBackground: !withDecoration,
        mode: HadithShareExportMode.cardOnly,
        fileName: 'hadith_${hadith.id}_${DateTime.now().millisecondsSinceEpoch}',
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: buildShareText(hadith),
        subject: 'Hadiz compartido desde Qibla Time',
      );
    } catch (e) {
      // Fallback: compartir solo texto si falla la imagen
      await shareHadithAsText(hadith);
    }
  }

  /// Comparte el hadiz como imagen con diseÃ±o islÃ¡mico decorativo
  Future<void> shareHadithAsDecoratedImage(
    Hadith hadith,
    QiblaTokens tokens,
  ) async {
    try {
      // Crear imagen con fondo decorativo
      final file = await HadithShareImageService.savePng(
        data: HadithShareData(
          arabicText: hadith.arabic,
          translation: hadith.translation,
          reference: hadith.reference,
          branding: 'Qibla Time',
        ),
        theme: HadithShareThemeData.fromTokens(
          tokens,
          transparentBackground: false,
        ),
        transparentBackground: false,
        mode: HadithShareExportMode.cardOnly,
        fileName: 'hadith_decorated_${hadith.id}',
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: buildShareText(hadith),
        subject: 'Hadiz compartido desde Qibla Time',
      );
    } catch (e) {
      // Fallback a imagen simple
      await shareHadithAsImage(hadith, tokens);
    }
  }

  /// Guarda el hadiz como imagen en el dispositivo
  Future<File?> saveHadithAsImage(
    Hadith hadith,
    QiblaTokens tokens, {
    String? directory,
  }) async {
    try {
      final file = await HadithShareImageService.savePng(
        data: HadithShareData(
          arabicText: hadith.arabic,
          translation: hadith.translation,
          reference: hadith.reference,
          branding: 'Qibla Time',
        ),
        theme: HadithShareThemeData.fromTokens(
          tokens,
          transparentBackground: false,
        ),
        transparentBackground: false,
        mode: HadithShareExportMode.cardOnly,
        fileName: 'hadith_${hadith.id}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Mover a directorio especificado si se proporciona
      if (directory != null) {
        final savedDir = Directory(directory);
        if (!await savedDir.exists()) {
          await savedDir.create(recursive: true);
        }
        final newPath = '$directory/hadith_${hadith.id}.png';
        await File(file.path).copy(newPath);
        return File(newPath);
      }

      return File(file.path);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene opciones de diseÃ±o disponibles para compartir
  List<ShareDesignOption> getAvailableDesigns() {
    return [
      ShareDesignOption(
        id: 'simple',
        name: 'Simple',
        description: 'Solo el texto del hadiz',
      ),
      ShareDesignOption(
        id: 'card',
        name: 'Tarjeta',
        description: 'Tarjeta con diseÃ±o islÃ¡mico',
      ),
      ShareDesignOption(
        id: 'decorated',
        name: 'Decorado',
        description: 'Imagen completa con decoraciÃ³n',
      ),
    ];
  }
}

/// OpciÃ³n de diseÃ±o para compartir
class ShareDesignOption {
  const ShareDesignOption({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}
