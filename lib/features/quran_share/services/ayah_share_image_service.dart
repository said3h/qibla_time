import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/ayah_share_data.dart';
import '../models/ayah_share_theme.dart';
import '../widgets/ayah_share_preview.dart';

enum AyahShareExportMode {
  storyCanvas,
  cardOnly,
}

class AyahShareImageService {
  static const _temporaryMaxAge = Duration(days: 1);
  static const _temporaryFilePrefixes = <String>[
    'ayah_',
    'ayah_share_card',
  ];

  static Future<Uint8List> capturePng({
    required AyahShareData data,
    AyahShareThemeData? theme,
    bool transparentBackground = true,
    AyahShareExportMode mode = AyahShareExportMode.storyCanvas,
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
        AyahShareThemeData.fromTokens(
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
          child: AyahSharePreview(
            data: data,
            theme: captureTheme,
            cardOnly: mode == AyahShareExportMode.cardOnly,
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
    required AyahShareData data,
    AyahShareThemeData? theme,
    bool transparentBackground = true,
    AyahShareExportMode mode = AyahShareExportMode.storyCanvas,
    String? fileName,
    Directory? directory,
  }) async {
    final bytes = await capturePng(
      data: data,
      theme: theme,
      transparentBackground: transparentBackground,
      mode: mode,
    );
    final targetDirectory = directory ?? await getTemporaryDirectory();
    await targetDirectory.create(recursive: true);
    await _deleteOldTemporaryFiles(targetDirectory);
    final sanitizedName = (fileName ?? 'ayah_share_card')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final resolvedFileName =
        sanitizedName.trim().isEmpty ? 'ayah_share_card' : sanitizedName;
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
        'Failed to clean old ayah share temporary files.',
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
      'Could not access a FlutterView for off-screen ayah rendering.',
    );
  }

  static Future<Uint8List> _pngBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Could not generate the ayah share image.');
    }
    return byteData.buffer.asUint8List();
  }
}
