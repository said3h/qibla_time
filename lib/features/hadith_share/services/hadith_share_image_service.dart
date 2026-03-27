import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/hadith_share_data.dart';
import '../models/hadith_share_theme.dart';
import '../widgets/hadith_share_preview.dart';

enum HadithShareExportMode {
  storyCanvas,
  cardOnly,
}

class HadithShareImageService {
  static const int _alphaCropThreshold = 2;

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
      return await _encodePngForMode(image, mode);
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
  }) async {
    final bytes = await capturePng(
      data: data,
      theme: theme,
      transparentBackground: transparentBackground,
      mode: mode,
    );
    final targetDirectory = directory ?? await getTemporaryDirectory();
    await targetDirectory.create(recursive: true);
    final sanitizedName = (fileName ?? 'hadith_share_card')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final resolvedFileName =
        sanitizedName.trim().isEmpty ? 'hadith_share_card' : sanitizedName;
    final file = File('${targetDirectory.path}/$resolvedFileName.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
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

  static Future<Uint8List> _encodePngForMode(
    ui.Image image,
    HadithShareExportMode mode,
  ) async {
    if (mode != HadithShareExportMode.cardOnly) {
      return _pngBytes(image);
    }

    try {
      final croppedImage = await _cropToVisibleBounds(image);
      if (identical(croppedImage, image)) {
        return _pngBytes(image);
      }

      try {
        return _pngBytes(croppedImage);
      } catch (_) {
        return _pngBytes(image);
      } finally {
        croppedImage.dispose();
      }
    } catch (_) {
      return _pngBytes(image);
    }
  }

  static Future<Uint8List> _pngBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Could not generate the hadith share image.');
    }
    return byteData.buffer.asUint8List();
  }

  static Future<ui.Image> _cropToVisibleBounds(ui.Image image) async {
    try {
      final rgbaData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgbaData == null) {
        return image;
      }

      final bytes = rgbaData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      int? left;
      int? top;
      int? right;
      int? bottom;

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final alpha = bytes[((y * width) + x) * 4 + 3];
          if (alpha <= _alphaCropThreshold) {
            continue;
          }

          left = left == null || x < left ? x : left;
          right = right == null || x > right ? x : right;
          top = top == null || y < top ? y : top;
          bottom = bottom == null || y > bottom ? y : bottom;
        }
      }

      if (left == null || top == null || right == null || bottom == null) {
        return image;
      }

      final cropWidth = right - left + 1;
      final cropHeight = bottom - top + 1;
      if (cropWidth == width && cropHeight == height) {
        return image;
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final src = Rect.fromLTWH(
        left.toDouble(),
        top.toDouble(),
        cropWidth.toDouble(),
        cropHeight.toDouble(),
      );
      final dst = Rect.fromLTWH(
        0,
        0,
        cropWidth.toDouble(),
        cropHeight.toDouble(),
      );

      canvas.drawImageRect(image, src, dst, Paint());
      final picture = recorder.endRecording();
      return picture.toImage(cropWidth, cropHeight);
    } catch (_) {
      return image;
    }
  }
}
