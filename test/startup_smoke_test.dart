import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/app/app_bootstrap.dart';

void main() {
  testWidgets('StartupShell paints first frame without plugins', (tester) async {
    await tester.pumpWidget(const StartupShell());
    await tester.pump();
    expect(find.text('Blockshade'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
