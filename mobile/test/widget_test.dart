import 'package:flutter_test/flutter_test.dart';
import 'package:smartnutri_mobile/main.dart';

void main() {
  testWidgets('SmartNutri smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartNutriApp());
    expect(find.text('SmartNutri'), findsOneWidget);
  });
}
