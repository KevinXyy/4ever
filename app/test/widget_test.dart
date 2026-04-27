import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_local/app.dart';

void main() {
  testWidgets('renders app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const GemmaLocalApp());

    expect(find.text('Gemma Local'), findsOneWidget);
  });
}
