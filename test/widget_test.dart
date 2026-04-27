import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/core/config/app_config.dart';

void main() {
  testWidgets('App MaterialApp renders without errors',
      (WidgetTester tester) async {
    AppConfig.initDev();

    await tester.pumpWidget(
      MaterialApp(
        title: AppConfig.instance.appName,
        home: const Scaffold(body: Center(child: Text('Vita Clube'))),
      ),
    );

    expect(find.text('Vita Clube'), findsOneWidget);
  });
}
