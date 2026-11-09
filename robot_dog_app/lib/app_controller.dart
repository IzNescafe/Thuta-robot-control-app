import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models/chat_message.dart';
import 'models/robot_state.dart';
import 'services/esp32_ble_service.dart';
import 'services/pi_service.dart';
import 'services/robot_preferences.dart';

class AppController extends ChangeNotifier {
  AppController({
    PiService? pi,
    Esp32BleService? ble,
    RobotPreferences? preferences,
  }) : pi = pi ?? PiService(),
       ble = ble ?? Esp32BleService(),
       preferences = preferences ?? RobotPreferences() {
    _piSubscription = this.pi.events.listen(_onPiEvent);
    _bleSubscription = this.ble.connectionChanges.listen((connected) {
      esp32Connected = connected;
      notifyListeners();
    });
    _loadProfile();
  }

  final PiService pi;
  final Esp32BleService ble;
  final RobotPreferences preferences;
  late final StreamSubscription<PiEvent> _piSubscription;
  late final StreamSubscription<bool> _bleSubscription;

  final messages = <ChatMessage>[
    ChatMessage(
      role: ChatRole.thuta,
      text: 'Hi! I am Thuta. Connect my Raspberry Pi to start chatting.',
      sentAt: DateTime.now(),
    ),
  ];
  RobotState robot = const RobotState();
  bool piConnected = false;
  bool esp32Connected = false;
  bool busy = false;
  bool profileLoaded = false;
  bool setupComplete = false;
  String robotName = 'Thuta';
  String piAddress = 'raspberrypi.local:8000';
  String? error;

  Future<void> _loadProfile() async {
    final profile = await preferences.load();
    robotName = profile.robotName;
    piAddress = profile.piAddress;
    setupComplete = profile.setupComplete;
    profileLoaded = true;
    notifyListeners();
  }

  Future<void> saveRobotProfile({
    required String name,
    required String address,
  }) async {
    final cleanName = name.trim();
    final cleanAddress = address.trim();
    if (cleanName.isEmpty || cleanAddress.isEmpty) {
      error = 'Robot name and Raspberry Pi address are required.';
      notifyListeners();
      return;
    }
    robotName = cleanName;
    piAddress = cleanAddress;
    setupComplete = true;
    error = null;
    await preferences.save(
      robotName: robotName,
      piAddress: piAddress,
      setupComplete: true,
    );
    notifyListeners();
  }

  Future<void> connectPi(String address) async {
    error = null;
    piAddress = address;
    await preferences.save(
      robotName: robotName,
      piAddress: piAddress,
      setupComplete: setupComplete,
    );
    notifyListeners();
    try {
      await pi.connect(address);
    } catch (e) {
      error = e.toString();
      piConnected = false;
      notifyListeners();
    }
  }

  Future<void> disconnectPi() async {
    await pi.disconnect();
    piConnected = false;
    notifyListeners();
  }

  Future<void> connectEsp32() async {
    error = null;
    notifyListeners();
    try {
      await ble.connect();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> disconnectEsp32() async {
    await ble.disconnect();
    esp32Connected = false;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void sendChat(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (!piConnected) {
      error = 'Connect to the Raspberry Pi before sending a message.';
      notifyListeners();
      return;
    }
    messages.add(
      ChatMessage(role: ChatRole.user, text: clean, sentAt: DateTime.now()),
    );
    busy = true;
    error = null;
    notifyListeners();
    pi.sendChat(clean);
  }

  Future<void> robotCommand(String command) async {
    error = null;
    try {
      await ble.send(command);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> emergencyStop() async {
    error = null;
    try {
      if (esp32Connected) await ble.emergencyStop();
      if (piConnected) pi.send({'type': 'emergency_stop'});
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  void _onPiEvent(PiEvent event) {
    switch (event.type) {
      case 'connection':
        piConnected = event.data['connected'] == true;
        if (!piConnected) robot = robot.copyWith(status: 'Offline');
        if (event.data['error'] != null) error = event.data['error'].toString();
      case 'state':
        robot = RobotState.fromJson(event.data);
      case 'chat_response':
        final reply = event.data['reply']?.toString() ?? '...';
        messages.add(
          ChatMessage(
            role: ChatRole.thuta,
            text: reply,
            sentAt: DateTime.now(),
          ),
        );
        robot = RobotState.fromJson(event.data);
        busy = false;
      case 'error':
        error =
            event.data['message']?.toString() ?? 'Unknown Raspberry Pi error';
        busy = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _piSubscription.cancel();
    _bleSubscription.cancel();
    pi.dispose();
    ble.dispose();
    super.dispose();
  }
}
