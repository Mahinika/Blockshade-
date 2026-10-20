import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/widgets/brass_star.dart';
import 'package:blockshade/widgets/level_complete_overlay.dart';
import 'package:blockshade/widgets/masking_tape.dart';

void main() {
  testWidgets('win stars sit on masking tape', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelCompleteOverlay(
            stars: 2,
            movesUsed: 5,
            parMoves: 6,
            onNext: () {},
            showNext: false,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final star = find.byType(BrassStar).first;
    expect(
      find.ancestor(of: star, matching: find.byType(MaskingTape)),
      findsWidgets,
    );
  });
}
