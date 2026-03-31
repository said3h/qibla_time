import 'package:flutter/material.dart';

import '../models/ayah_share_data.dart';
import '../models/ayah_share_theme.dart';
import 'ayah_share_card.dart';

class AyahSharePreview extends StatelessWidget {
  const AyahSharePreview({
    super.key,
    required this.data,
    required this.theme,
    this.cardOnly = false,
  });

  final AyahShareData data;
  final AyahShareThemeData theme;
  final bool cardOnly;

  @override
  Widget build(BuildContext context) {
    final maxCardWidth = theme.canvasSize.width - theme.canvasPadding.horizontal;
    final maxCardHeight =
        theme.canvasSize.height - theme.canvasPadding.vertical;
    final targetCardWidth = theme.canvasSize.width * theme.cardWidthFactor;
    final cardWidth =
        targetCardWidth < maxCardWidth ? targetCardWidth : maxCardWidth;
    final card = SizedBox(
      width: cardWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        child: AyahShareCard(
          data: data,
          theme: theme,
        ),
      ),
    );

    if (cardOnly) {
      return card;
    }

    return ColoredBox(
      color: theme.canvasBackgroundColor,
      child: SizedBox(
        width: theme.canvasSize.width,
        height: theme.canvasSize.height,
        child: Center(
          child: Padding(
            padding: theme.canvasPadding,
            child: card,
          ),
        ),
      ),
    );
  }
}
