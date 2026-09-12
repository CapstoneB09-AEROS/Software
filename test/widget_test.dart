import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_co2/main.dart';

void main() {
  testWidgets('Monitoring CO2 app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MonitoringApp());

    expect(find.text('Kualitas Udara'), findsOneWidget);
    expect(find.text('Karbon Monoksida (CO)'), findsOneWidget);
    expect(find.text('Karbon Dioksida (CO₂)'), findsOneWidget);
    expect(find.text('Status Sistem'), findsOneWidget);
  });
}