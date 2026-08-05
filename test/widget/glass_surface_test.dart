import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_glass_surface.dart';

void main() {
  testWidgets('RitmoGlassSurface renders BackdropFilter when reduceTransparency is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RitmoTheme.build(
          palette: RitmoPalette.jadeNoir,
          brightness: Brightness.dark,
          reduceTransparency: false,
        ),
        home: const Scaffold(
          body: RitmoGlassSurface(
            child: Text('Glass Content'),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Glass Content'), findsOneWidget);
  });

  testWidgets('RitmoGlassSurface fallback to opaque container without BackdropFilter when reduceTransparency is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RitmoTheme.build(
          palette: RitmoPalette.jadeNoir,
          brightness: Brightness.dark,
          reduceTransparency: true,
        ),
        home: const Scaffold(
          body: RitmoGlassSurface(
            child: Text('Opaque Content'),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('Opaque Content'), findsOneWidget);
  });
}
