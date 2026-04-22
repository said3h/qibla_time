import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/hadith_share_data.dart';
import '../models/hadith_share_theme.dart';
import '../widgets/hadith_share_preview.dart';

enum HadithShareExportMode {
  storyCanvas,
  cardOnly,
}

class HadithShareImageService {
  static const _temporaryMaxAge = Duration(days: 1);
  static const _temporaryFilePrefixes = <String>[
    'hadith_',
    'hadith_share_card',
    'dua_',
  ];

  static Future<Uint8List> capturePng({
    required HadithShareData data,
    HadithShareThemeData? theme,
    bool transparentBackground = true,
    HadithShareExportMode mode = HadithShareExportMode.storyCanvas,
    double pixelRatio = 1.0,
  }) async {
    if (pixelRatio <= 0) {
      throw ArgumentError.value(
        pixelRatio,
        'pixelRatio',
        'pixelRatio must be greater than zero.',
      );
    }

    WidgetsFlutterBinding.ensureInitialized();

    final baseTheme = theme ??
        HadithShareThemeData.fromTokens(
          QiblaThemes.current,
          transparentBackground: transparentBackground,
        );
    final captureTheme = baseTheme.copyWith(
      canvasBackgroundColor: transparentBackground
          ? Colors.transparent
          : baseTheme.canvasBackgroundColor,
    );

    final repaintBoundary = RenderRepaintBoundary();
    final view = _resolveFlutterView();
    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(captureTheme.canvasSize),
        physicalConstraints: BoxConstraints.tight(captureTheme.canvasSize),
        devicePixelRatio: 1.0,
      ),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
    );

    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    final focusManager = FocusManager();
    final buildOwner = BuildOwner(focusManager: focusManager);
    renderView.prepareInitialFrame();

    final rootWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(
          size: captureTheme.canvasSize,
          devicePixelRatio: 1.0,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: HadithSharePreview(
            data: data,
            theme: captureTheme,
            cardOnly: mode == HadithShareExportMode.cardOnly,
          ),
        ),
      ),
    );

    ui.Image? image;

    try {
      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: rootWidget,
      ).attachToRenderTree(buildOwner);

      buildOwner
        ..buildScope(rootElement)
        ..finalizeTree();

      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
      return _pngBytes(image);
    } finally {
      image?.dispose();
      renderView.child = null;
      pipelineOwner.rootNode = null;
      focusManager.dispose();
    }
  }

  static Future<File> savePng({
    required HadithShareData data,
    HadithShareThemeData? theme,
    bool transparentBackground = true,
    HadithShareExportMode mode = HadithShareExportMode.storyCanvas,
    String? fileName,
    Directory? directory,
    double pixelRatio = 1.0,
  }) async {
    final bytes = await capturePng(
      data: data,
      theme: theme,
      transparentBackground: transparentBackground,
      mode: mode,
      pixelRatio: pixelRatio,
    );
    final targetDirectory = directory ?? await getTemporaryDirectory();
    await targetDirectory.create(recursive: true);
    await _deleteOldTemporaryFiles(targetDirectory);
    final sanitizedName = (fileName ?? 'hadith_share_card')
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final resolvedFileName =
        sanitizedName.isEmpty ? 'hadith_share_card' : sanitizedName;
    final file = File('${targetDirectory.path}/$resolvedFileName.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> _deleteOldTemporaryFiles(Directory directory) async {
    final cutoff = DateTime.now().subtract(_temporaryMaxAge);
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!_temporaryFilePrefixes.any(name.startsWith)) continue;
        final modified = await entity.lastModified();
        if (modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to clean old hadith share temporary files.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static ui.FlutterView _resolveFlutterView() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    if (dispatcher.implicitView != null) {
      return dispatcher.implicitView!;
    }
    if (dispatcher.views.isNotEmpty) {
      return dispatcher.views.first;
    }
    throw StateError(
      'Could not access a FlutterView for off-screen hadith rendering.',
    );
  }

  static Future<Uint8List> _pngBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Could not generate the hadith share image.');
    }
    return byteData.buffer.asUint8List();
  }
}
