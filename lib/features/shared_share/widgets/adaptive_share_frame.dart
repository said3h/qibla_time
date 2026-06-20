import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AdaptiveShareFrame extends StatefulWidget {
  const AdaptiveShareFrame({
    super.key,
    required this.assetPath,
    required this.accentColor,
    required this.borderRadius,
    this.cornerSize = 156,
    this.sourceCornerSize = 330,
    this.sourceLineInset = 28,
    this.lineThickness = 2.2,
  });

  final String assetPath;
  final Color accentColor;
  final double borderRadius;
  final double cornerSize;
  final double sourceCornerSize;
  final double sourceLineInset;
  final double lineThickness;

  @override
  State<AdaptiveShareFrame> createState() => _AdaptiveShareFrameState();
}

class _AdaptiveShareFrameState extends State<AdaptiveShareFrame> {
  ImageStream? _stream;
  ImageInfo? _imageInfo;
  late final ImageStreamListener _listener = ImageStreamListener(_handleImage);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(AdaptiveShareFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  void _resolveImage() {
    _stream?.removeListener(_listener);
    final stream = AssetImage(widget.assetPath).resolve(
      createLocalImageConfiguration(context),
    );
    _stream = stream;
    stream.addListener(_listener);
  }

  void _handleImage(ImageInfo imageInfo, bool synchronousCall) {
    if (!mounted) {
      return;
    }
    setState(() {
      _imageInfo = imageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _imageInfo?.image;
    return IgnorePointer(
      child: CustomPaint(
        painter: _AdaptiveShareFramePainter(
          image: image,
          accentColor: widget.accentColor,
          borderRadius: widget.borderRadius,
          cornerSize: widget.cornerSize,
          sourceCornerSize: widget.sourceCornerSize,
          sourceLineInset: widget.sourceLineInset,
          lineThickness: widget.lineThickness,
        ),
      ),
    );
  }
}

class _AdaptiveShareFramePainter extends CustomPainter {
  const _AdaptiveShareFramePainter({
    required this.image,
    required this.accentColor,
    required this.borderRadius,
    required this.cornerSize,
    required this.sourceCornerSize,
    required this.sourceLineInset,
    required this.lineThickness,
  });

  final ui.Image? image;
  final Color accentColor;
  final double borderRadius;
  final double cornerSize;
  final double sourceCornerSize;
  final double sourceLineInset;
  final double lineThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final borderRect = Rect.fromLTWH(
      1.5,
      1.5,
      size.width - 3,
      size.height - 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        borderRect,
        Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    final frameImage = image;
    if (frameImage == null || size.isEmpty) {
      return;
    }

    final imageWidth = frameImage.width.toDouble();
    final imageHeight = frameImage.height.toDouble();
    final sourceCorner = sourceCornerSize
        .clamp(1.0, imageWidth < imageHeight ? imageWidth / 2 : imageHeight / 2)
        .toDouble();
    final corner = cornerSize
        .clamp(1.0, size.width < size.height ? size.width / 2 : size.height / 2)
        .toDouble();
    final lineInset = (sourceLineInset * corner / sourceCorner)
        .clamp(2.0, corner * 0.28)
        .toDouble();
    final linePaint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    void drawPart(Rect source, Rect destination) {
      if (destination.width <= 0 || destination.height <= 0) {
        return;
      }
      canvas.drawImageRect(frameImage, source, destination, linePaint);
    }

    final rightSourceX = imageWidth - sourceCorner;
    final bottomSourceY = imageHeight - sourceCorner;
    drawPart(
      Rect.fromLTWH(0, 0, sourceCorner, sourceCorner),
      Rect.fromLTWH(0, 0, corner, corner),
    );
    drawPart(
      Rect.fromLTWH(rightSourceX, 0, sourceCorner, sourceCorner),
      Rect.fromLTWH(size.width - corner, 0, corner, corner),
    );
    drawPart(
      Rect.fromLTWH(0, bottomSourceY, sourceCorner, sourceCorner),
      Rect.fromLTWH(0, size.height - corner, corner, corner),
    );
    drawPart(
      Rect.fromLTWH(rightSourceX, bottomSourceY, sourceCorner, sourceCorner),
      Rect.fromLTWH(size.width - corner, size.height - corner, corner, corner),
    );

    final sourceLineThickness = (sourceLineInset * 0.72).clamp(4.0, 24.0);
    final horizontalSourceWidth = imageWidth - (sourceCorner * 2);
    final verticalSourceHeight = imageHeight - (sourceCorner * 2);
    final horizontalDestinationWidth = size.width - (corner * 2) + lineInset;
    final verticalDestinationHeight = size.height - (corner * 2) + lineInset;
    final lineOffset = lineInset;
    final lineStart = corner - (lineInset * 0.5);

    drawPart(
      Rect.fromLTWH(
        sourceCorner,
        sourceLineInset,
        horizontalSourceWidth,
        sourceLineThickness,
      ),
      Rect.fromLTWH(
        lineStart,
        lineOffset,
        horizontalDestinationWidth,
        lineThickness,
      ),
    );
    drawPart(
      Rect.fromLTWH(
        sourceCorner,
        imageHeight - sourceLineInset - sourceLineThickness,
        horizontalSourceWidth,
        sourceLineThickness,
      ),
      Rect.fromLTWH(
        lineStart,
        size.height - lineOffset - lineThickness,
        horizontalDestinationWidth,
        lineThickness,
      ),
    );
    drawPart(
      Rect.fromLTWH(
        sourceLineInset,
        sourceCorner,
        sourceLineThickness,
        verticalSourceHeight,
      ),
      Rect.fromLTWH(
        lineOffset,
        lineStart,
        lineThickness,
        verticalDestinationHeight,
      ),
    );
    drawPart(
      Rect.fromLTWH(
        imageWidth - sourceLineInset - sourceLineThickness,
        sourceCorner,
        sourceLineThickness,
        verticalSourceHeight,
      ),
      Rect.fromLTWH(
        size.width - lineOffset - lineThickness,
        lineStart,
        lineThickness,
        verticalDestinationHeight,
      ),
    );
  }

  @override
  bool shouldRepaint(_AdaptiveShareFramePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.cornerSize != cornerSize ||
        oldDelegate.sourceCornerSize != sourceCornerSize ||
        oldDelegate.sourceLineInset != sourceLineInset ||
        oldDelegate.lineThickness != lineThickness;
  }
}
