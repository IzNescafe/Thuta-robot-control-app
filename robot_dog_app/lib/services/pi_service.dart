import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class PiEvent {
  const PiEvent(this.type, this.data);
  final String type;
  final Map<String, dynamic> data;
}

class PiService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _events = StreamController<PiEvent>.broadcast();

  Stream<PiEvent> get events => _events.stream;
  bool get isConnected => _channel != null;

  Future<void> connect(String address) async {
    await disconnect();
    var value = address.trim();
    if (!value.startsWith('ws://') && !value.startsWith('wss://')) {
      value = 'ws://$value';
    }
    if (!value.endsWith('/ws'))
      value = '${value.replaceFirst(RegExp(r'/$'), '')}/ws';

    final channel = WebSocketChannel.connect(Uri.parse(value));
    await channel.ready.timeout(const Duration(seconds: 8));
    _channel = channel;
    _subscription = channel.stream.listen(
      _handleMessage,
      onError: (Object error) => _closeWithReason(error.toString()),
      onDone: () => _closeWithReason('Raspberry Pi disconnected'),
    );
    _events.add(const PiEvent('connection', {'connected': true}));
    send({'type': 'get_state'});
  }

  void _handleMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is Map<String, dynamic>) {
        _events.add(PiEvent(decoded['type']?.toString() ?? 'event', decoded));
      }
    } catch (_) {
      _events.add(PiEvent('log', {'message': raw.toString()}));
    }
  }

  void send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) throw StateError('Connect to Raspberry Pi first.');
    channel.sink.add(jsonEncode(payload));
  }

  void sendChat(String text) => send({'type': 'chat', 'text': text});

  void _closeWithReason(String reason) {
    _channel = null;
    _events.add(PiEvent('connection', {'connected': false, 'error': reason}));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}
