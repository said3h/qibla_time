import 'package:flutter/material.dart';

import '../models/hadith_share_data.dart';
import '../models/hadith_share_theme.dart';
import 'hadith_share_card.dart';

class HadithSharePreview extends StatelessWidget {
  const HadithSharePreview({
    super.key,
    required this.data,
    required this.theme,
    this.cardOnly = false,
  });

  final HadithShareData data;
  final HadithShareThemeData theme;
  final bool cardOnly;

  @override
  Widget build(BuildContext context) {
    final maxCardWidth = theme.canvasSize.width - theme.canvasPadding.horizontal;
    final maxCardHeight = theme.canvasSize.height - theme.canvasPadding.vertical;
    final targetCardWidth = theme.canvasSize.width * theme.cardWidthFactor;
    final cardWidth =
        targetCardWidth < maxCardWidth ? targetCardWidth : maxCardWidth;
    final card = SizedBox(
      width: cardWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        child: HadithShareCard(
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
