import 'package:flutter/material.dart';

/// A short label that stays on one line (segmented buttons, chart axes, fixed-width
/// columns): with a big phone font it gets a little smaller instead of breaking in the
/// middle of the word ("Overvie / w", "Threshol / d" on the owner's Galaxy, 2026-11-19).
class OneLine extends StatelessWidget {
  const OneLine(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: switch (textAlign) {
      TextAlign.end || TextAlign.right => Alignment.centerRight,
      TextAlign.center => Alignment.center,
      _ => Alignment.centerLeft,
    },
    child: Text(text, maxLines: 1, softWrap: false, style: style, textAlign: textAlign),
  );
}
