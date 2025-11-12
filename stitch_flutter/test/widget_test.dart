// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:stitch_flutter/main.dart';

void main() {
  testWidgets('主页底部导航渲染', (WidgetTester tester) async {
    await tester.pumpWidget(const StitchApp());

    expect(find.text('首页'), findsWidgets);
    expect(find.text('我的衣柜'), findsOneWidget);
    expect(find.text('AI试穿室'), findsOneWidget);
    expect(find.text('我的'), findsWidgets);
  });
}
