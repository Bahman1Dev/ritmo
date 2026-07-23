import 'package:flutter/material.dart';

/// Parses basic markdown tags (bold: `**text**` and italic: `*text*`) into a list of TextSpans.
List<TextSpan> parseMarkdownText(String text, TextStyle baseStyle) {
  final spans = <TextSpan>[];
  final regExp = RegExp(r'(\*\*.*?\*\*|\*.*?\*)');
  var lastMatchEnd = 0;

  final matches = regExp.allMatches(text);
  for (final match in matches) {
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd, match.start),
        style: baseStyle,
      ));
    }
    
    final matchedText = match.group(0)!;
    if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
      if (matchedText.length >= 4) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else {
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle,
        ));
      }
    } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
      if (matchedText.length >= 2) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else {
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle,
        ));
      }
    }
    
    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastMatchEnd),
      style: baseStyle,
    ));
  }

  return spans;
}
