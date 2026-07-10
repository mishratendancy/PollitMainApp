import 'package:flutter_test/flutter_test.dart';

import 'package:pollit/main.dart';

void main() {
  testWidgets('Pollit app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const PollitApp());
    await tester.pump();
    expect(find.text('Pollit'), findsOneWidget);
  });
}
