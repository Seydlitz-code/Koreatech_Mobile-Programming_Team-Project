import 'package:material_ui/material_ui.dart';

/// [ranges] 구간을 강조해서 보여 주는 텍스트.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.ranges,
    this.maxLines,
  });

  final String text;

  /// 강조할 [start, end) 구간. 겹치지 않고 시작 순이어야 한다.
  final List<(int start, int end)> ranges;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlight = TextStyle(
      fontWeight: FontWeight.w700,
      color: scheme.onTertiaryContainer,
      backgroundColor: scheme.tertiaryContainer,
    );

    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in ranges) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      spans.add(TextSpan(text: text.substring(start, end), style: highlight));
      at = end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
