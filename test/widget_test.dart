import 'package:callcenter_salonuser_mobil/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const SalonStaffApp());
    await tester.pump();
    expect(find.byType(SalonStaffApp), findsOneWidget);
  });
}
