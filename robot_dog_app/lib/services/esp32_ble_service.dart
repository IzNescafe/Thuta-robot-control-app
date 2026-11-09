import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Esp32BleService {
  static const deviceName = 'RobotDog-Control';
  static final serviceUuid = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  static final controlUuid = Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');

  final _connection = StreamController<bool>.broadcast();
  BluetoothDevice? _device;
  BluetoothCharacteristic? _control;
  StreamSubscription<BluetoothConnectionState>? _stateSubscription;

  Stream<bool> get connectionChanges => _connection.stream;
  bool get isConnected => _control != null;

  Future<void> connect() async {
    if (!await FlutterBluePlus.isSupported) {
      throw StateError('Bluetooth LE is not supported on this device.');
    }
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first
        .timeout(const Duration(seconds: 15));

    BluetoothDevice? found;
    final scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        if (result.advertisementData.advName == deviceName ||
            result.device.platformName == deviceName) {
          found = result.device;
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });
    await FlutterBluePlus.startScan(
      withServices: [serviceUuid],
      timeout: const Duration(seconds: 12),
    );
    await FlutterBluePlus.isScanning.where((value) => !value).first;
    await scanSubscription.cancel();
    if (found == null) throw StateError('$deviceName was not found.');

    _device = found;
    // This is an educational, non-commercial robot project.
    await found!.connect(license: License.nonprofit);
    _stateSubscription = found!.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _control = null;
        _connection.add(false);
      }
    });

    final services = await found!.discoverServices();
    for (final service in services) {
      if (service.uuid == serviceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == controlUuid) _control = characteristic;
        }
      }
    }
    if (_control == null) {
      await disconnect();
      throw StateError('RobotDog BLE control characteristic was not found.');
    }
    _connection.add(true);
  }

  Future<void> send(String command) async {
    final control = _control;
    if (control == null) throw StateError('Connect to ESP32 first.');
    final bytes = utf8.encode(command);
    await control.write(
      bytes,
      withoutResponse: control.properties.writeWithoutResponse,
    );
  }

  Future<void> emergencyStop() async {
    if (_control != null) await send('OFF');
  }

  Future<void> disconnect() async {
    _control = null;
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _device?.disconnect();
    _device = null;
    _connection.add(false);
  }

  Future<void> dispose() async {
    await disconnect();
    await _connection.close();
  }
}
