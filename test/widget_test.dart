import 'package:flutter_test/flutter_test.dart';

import 'package:todo_app/main.dart';

void main() {
  testWidgets('Onboarding screen shows welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text("Let's get you set up"), findsOneWidget);
  });

  testWidgets('Theme preview cards are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Baby Blue'), findsOneWidget);
    expect(find.text('Green'), findsOneWidget);
  });
}
