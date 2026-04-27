import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MindBloomApp());
    await tester.pumpAndSettle();
  });
}
