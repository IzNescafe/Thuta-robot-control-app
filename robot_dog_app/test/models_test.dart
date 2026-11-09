import 'package:flutter_test/flutter_test.dart';
import 'package:robot_dog_app/models/robot_state.dart';

void main() {
  test('robot state parses Pi payload', () {
    final state = RobotState.fromJson({
      'status': 'Speaking',
      'emotion': 'excited',
      'action': 'happy_bounce',
      'energy': 74.6,
      'tracking': true,
    });
    expect(state.emotion, 'EXCITED');
    expect(state.energy, 75);
    expect(state.tracking, isTrue);
  });
}
