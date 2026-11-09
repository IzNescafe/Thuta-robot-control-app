import 'package:flutter_test/flutter_test.dart';
import 'package:robot_dog_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Thuta chat screen loads', (tester) async {
    SharedPreferences.setMockInitialValues({
      'robot_name': 'Thuta',
      'pi_address': 'raspberrypi.local:8000',
      'setup_complete': true,
    });
    await tester.pumpWidget(const ThutaApp());
    await tester.pumpAndSettle();

    expect(find.text('THUTA AI'), findsOneWidget);
    expect(find.text('Message Thuta…'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Robot'), findsOneWidget);
    expect(find.text('Setup'), findsOneWidget);
  });
}
