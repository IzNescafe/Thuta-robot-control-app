import 'package:shared_preferences/shared_preferences.dart';

class RobotPreferences {
  static const _robotNameKey = 'robot_name';
  static const _piAddressKey = 'pi_address';
  static const _setupCompleteKey = 'setup_complete';

  Future<RobotProfile> load() async {
    final preferences = await SharedPreferences.getInstance();
    return RobotProfile(
      robotName: preferences.getString(_robotNameKey) ?? 'Thuta',
      piAddress:
          preferences.getString(_piAddressKey) ?? 'raspberrypi.local:8000',
      setupComplete: preferences.getBool(_setupCompleteKey) ?? false,
    );
  }

  Future<void> save({
    required String robotName,
    required String piAddress,
    required bool setupComplete,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_robotNameKey, robotName.trim());
    await preferences.setString(_piAddressKey, piAddress.trim());
    await preferences.setBool(_setupCompleteKey, setupComplete);
  }
}

class RobotProfile {
  const RobotProfile({
    required this.robotName,
    required this.piAddress,
    required this.setupComplete,
  });

  final String robotName;
  final String piAddress;
  final bool setupComplete;
}
