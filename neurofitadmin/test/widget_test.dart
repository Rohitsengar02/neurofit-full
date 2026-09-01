import 'package:flutter_test/flutter_test.dart';
import 'package:neurofitadmin/main.dart';

void main() {
  testWidgets('Admin app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroFitAdminApp());
  });
}
