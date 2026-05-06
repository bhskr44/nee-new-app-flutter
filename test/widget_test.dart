import 'package:flutter_test/flutter_test.dart';
import 'package:nee_construction_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NEEApp());
    expect(find.text('NEE Construction'), findsWidgets);
  });
}
