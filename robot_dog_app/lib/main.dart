import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'models/chat_message.dart';

void main() => runApp(const ThutaApp());

class ThutaApp extends StatelessWidget {
  const ThutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7557D5),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thuta AI',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0D14),
        cardTheme: CardThemeData(
          color: const Color(0xFF141925),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF272E40)),
          ),
        ),
      ),
      home: const ThutaHome(),
    );
  }
}

class ThutaHome extends StatefulWidget {
  const ThutaHome({super.key});

  @override
  State<ThutaHome> createState() => _ThutaHomeState();
}

class _ThutaHomeState extends State<ThutaHome> {
  final controller = AppController();
  final input = TextEditingController();
  final scroll = ScrollController();
  int tab = 0;
  String controlMode = 'OFF';
  double driveSpeed = 150;
  bool alertSystemArmed = true;
  bool faceRecognitionEnabled = true;
  bool cameraPreviewOn = true;

  @override
  void dispose() {
    controller.dispose();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.profileLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!controller.setupComplete) {
          return _RobotSetupPage(controller: controller, firstRun: true);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [Text('🐶'), SizedBox(width: 10), Text('THUTA AI')],
            ),
            actions: [
              _StatusDot(label: 'PI', connected: controller.piConnected),
              _StatusDot(label: 'ESP', connected: controller.esp32Connected),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _RobotStrip(controller: controller),
                if (controller.error != null)
                  MaterialBanner(
                    content: Text(controller.error!),
                    actions: [
                      TextButton(
                        onPressed: controller.clearError,
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                Expanded(
                  child: switch (tab) {
                    0 => _chat(),
                    1 => _controls(),
                    2 => _alerts(),
                    3 => _recognition(),
                    _ => _RobotSetupPage(controller: controller),
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.gamepad_outlined),
                label: 'Robot',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.face_retouching_natural),
                selectedIcon: Icon(Icons.face_retouching_natural),
                label: 'Faces',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                label: 'Setup',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chat() => Column(
    children: [
      Expanded(
        child: ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          itemCount: controller.messages.length,
          itemBuilder: (_, index) =>
              _MessageBubble(message: controller.messages[index]),
        ),
      ),
      if (controller.busy)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Thuta is thinking…'),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Message Thuta…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    ],
  );

  void _send() {
    final text = input.text;
    input.clear();
    controller.sendChat(text);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _setMode(String mode) async {
    if (mode == 'OFF') {
      await controller.emergencyStop();
    } else {
      await controller.robotCommand(mode);
    }
    if (mounted) setState(() => controlMode = mode);
  }

  Widget _controls() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 780;
      final connection = _ConnectionCard(controller: controller);
      final controlPanel = _ControlPanel(
        mode: controlMode,
        speed: driveSpeed.round(),
        onMode: _setMode,
        onCommand: controller.robotCommand,
        onSpeed: (value) {
          setState(() => driveSpeed = value);
          controller.robotCommand('SPEED=${value.round()}');
        },
      );
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0x1A7C5CFF), Color(0x000A0D14)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 18, wide ? 28 : 16, 28),
          children: [
            const _ControlHeader(),
            const SizedBox(height: 18),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        connection,
                        const SizedBox(height: 16),
                        _TelemetryCard(controller: controller),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(flex: 6, child: controlPanel),
                ],
              )
            else ...[
              controlPanel,
              const SizedBox(height: 16),
              _TelemetryCard(controller: controller),
              const SizedBox(height: 16),
              connection,
            ],
            const SizedBox(height: 18),
            _EmergencyButton(
              onPressed: () async {
                await controller.emergencyStop();
                if (mounted) setState(() => controlMode = 'OFF');
              },
            ),
          ],
        ),
      );
    },
  );

  Widget _alerts() => _AlertCenter(
    armed: alertSystemArmed,
    piOnline: controller.piConnected,
    espOnline: controller.esp32Connected,
    onArmChanged: (value) => setState(() => alertSystemArmed = value),
    onEmergencyStop: () async {
      await controller.emergencyStop();
      if (mounted) setState(() => controlMode = 'OFF');
    },
  );

  Widget _recognition() => _FaceRecognitionCenter(
    enabled: faceRecognitionEnabled,
    previewOn: cameraPreviewOn,
    piOnline: controller.piConnected,
    onEnabledChanged: (value) => setState(() => faceRecognitionEnabled = value),
    onPreviewChanged: (value) => setState(() => cameraPreviewOn = value),
  );
}

class _AlertCenter extends StatelessWidget {
  const _AlertCenter({
    required this.armed,
    required this.piOnline,
    required this.espOnline,
    required this.onArmChanged,
    required this.onEmergencyStop,
  });

  final bool armed;
  final bool piOnline;
  final bool espOnline;
  final ValueChanged<bool> onArmChanged;
  final VoidCallback onEmergencyStop;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const _PageIntro(
        icon: Icons.notifications_active_rounded,
        title: 'SAFETY & ALERT CENTER',
        subtitle: 'Monitor Thuta and decide how the team should be notified.',
      ),
      const SizedBox(height: 18),
      Card(
        color: armed ? const Color(0xFF182B29) : const Color(0xFF24202A),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: armed ? const Color(0xFF245D51) : const Color(0xFF3B3545),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  armed ? Icons.shield_rounded : Icons.shield_outlined,
                  color: armed ? const Color(0xFF64E6B2) : const Color(0xFFC5BED7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(armed ? 'Alert protection is armed' : 'Alerts are paused', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(armed ? 'Thuta will flag safety and connection events.' : 'No push alerts will be sent.', style: const TextStyle(color: Color(0xFFABB5C8))),
                  ],
                ),
              ),
              Switch(value: armed, onChanged: onArmChanged),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const _SectionLabel(icon: Icons.tune_rounded, title: 'ALERT RULES'),
      const SizedBox(height: 10),
      _AlertRule(icon: Icons.warning_amber_rounded, color: Color(0xFFFFB85C), title: 'Obstacle or cliff detected', detail: 'Stop motion and notify the operator', enabled: armed),
      _AlertRule(icon: Icons.battery_alert_rounded, color: Color(0xFFFF7B8B), title: 'Low robot battery', detail: 'Notify below 20% charge', enabled: armed),
      _AlertRule(icon: Icons.wifi_off_rounded, color: Color(0xFFA996FF), title: 'Connection lost', detail: 'Raspberry Pi or ESP32 becomes unavailable', enabled: armed),
      _AlertRule(icon: Icons.person_search_rounded, color: Color(0xFF55CFFB), title: 'Unknown face observed', detail: 'Save an event for operator review', enabled: armed),
      const SizedBox(height: 16),
      const _SectionLabel(icon: Icons.history_rounded, title: 'LIVE STATUS'),
      const SizedBox(height: 10),
      Card(child: Column(children: [
        _StatusRow(icon: Icons.memory_rounded, title: 'Raspberry Pi brain', online: piOnline),
        const Divider(height: 1),
        _StatusRow(icon: Icons.bluetooth_rounded, title: 'ESP32 motion controller', online: espOnline),
      ])),
      const SizedBox(height: 18),
      _EmergencyButton(onPressed: onEmergencyStop),
      const SizedBox(height: 10),
      const Text('Prototype UI: connect the Pi alert service to deliver real push notifications, sound alarms, and saved event history.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7E879A), fontSize: 12)),
    ],
  );
}

class _FaceRecognitionCenter extends StatelessWidget {
  const _FaceRecognitionCenter({required this.enabled, required this.previewOn, required this.piOnline, required this.onEnabledChanged, required this.onPreviewChanged});
  final bool enabled;
  final bool previewOn;
  final bool piOnline;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onPreviewChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const _PageIntro(icon: Icons.face_retouching_natural, title: 'FACE RECOGNITION', subtitle: 'See who Thuta recognizes through its Raspberry Pi camera.'),
      const SizedBox(height: 18),
      AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF364159))),
          child: Stack(children: [
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(previewOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, size: 52, color: const Color(0xFFA996FF)),
              const SizedBox(height: 8),
              Text(previewOn ? (piOnline ? 'Camera stream ready to connect' : 'Connect Raspberry Pi for camera stream') : 'Camera preview paused', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            ])),
            Positioned(top: 14, left: 14, child: _LivePill(online: previewOn && piOnline)),
            Positioned(right: 10, bottom: 8, child: IconButton.filledTonal(onPressed: () => onPreviewChanged(!previewOn), icon: Icon(previewOn ? Icons.pause_rounded : Icons.play_arrow_rounded))),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.person_search_rounded, color: Color(0xFF55CFFB)), title: const Text('Enable face recognition', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Identify approved people or flag an unknown face.'), value: enabled, onChanged: onEnabledChanged),
        const Divider(),
        ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.add_a_photo_outlined)), title: const Text('Enroll a person'), subtitle: const Text('Capture labeled photos from the Pi camera'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _showPrototype(context, 'Enrollment will open after the Pi camera service is linked.')),
      ]))),
      const SizedBox(height: 16),
      const _SectionLabel(icon: Icons.groups_rounded, title: 'RECOGNITION RESULTS'),
      const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
        const Icon(Icons.manage_search_rounded, size: 38, color: Color(0xFF7E879A)),
        const SizedBox(height: 8),
        const Text('No recognition events yet', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('When enabled, recognized people and unknown-face alerts will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9AA4B8))),
      ]))),
      const SizedBox(height: 10),
      const Text('Privacy: enroll people only with permission. Keep face images and event records on the secured Pi.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7E879A), fontSize: 12)),
    ],
  );

  void _showPrototype(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFF29213E), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: const Color(0xFFA996FF))),
    const SizedBox(width: 13),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: .3)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Color(0xFF929BB1)))])),
  ]);
}

class _AlertRule extends StatelessWidget {
  const _AlertRule({required this.icon, required this.color, required this.title, required this.detail, required this.enabled});
  final IconData icon; final Color color; final String title; final String detail; final bool enabled;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 9), child: ListTile(leading: Icon(icon, color: color), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(detail), trailing: Icon(enabled ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded, color: enabled ? const Color(0xFF58E39B) : const Color(0xFF7E879A))));
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.title, required this.online});
  final IconData icon; final String title; final bool online;
  @override
  Widget build(BuildContext context) => ListTile(leading: Icon(icon, color: const Color(0xFFA996FF)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: Text(online ? 'ONLINE' : 'OFFLINE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: online ? const Color(0xFF58E39B) : const Color(0xFFFF7B8B))));
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.online}); final bool online;
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: const Color(0xD90A0D14), borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(online ? Icons.circle : Icons.cloud_off_rounded, size: 11, color: online ? const Color(0xFF58E39B) : const Color(0xFFFFB85C)), const SizedBox(width: 5), Text(online ? 'LIVE' : 'WAITING', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))])));
}

class _RobotSetupPage extends StatefulWidget {
  const _RobotSetupPage({required this.controller, this.firstRun = false});

  final AppController controller;
  final bool firstRun;

  @override
  State<_RobotSetupPage> createState() => _RobotSetupPageState();
}

class _RobotSetupPageState extends State<_RobotSetupPage> {
  late final TextEditingController name;
  late final TextEditingController address;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.controller.robotName);
    address = TextEditingController(text: widget.controller.piAddress);
  }

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await widget.controller.saveRobotProfile(
      name: name.text,
      address: address.text,
    );
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.pets_rounded, size: 58, color: Color(0xFFA996FF)),
        const SizedBox(height: 12),
        Text(
          widget.firstRun ? 'Add your RobotDog' : 'Robot setup',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Save this robot once, then reconnect its Raspberry Pi and ESP32 whenever you use it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF929BB1)),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(
                  icon: Icons.badge_outlined,
                  title: 'ROBOT PROFILE',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Robot name',
                    prefixIcon: Icon(Icons.smart_toy_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: address,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Raspberry Pi address',
                    hintText: 'raspberrypi.local:8000',
                    prefixIcon: Icon(Icons.lan_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      widget.firstRun ? 'Save & continue' : 'Save changes',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(
                  icon: Icons.cable_rounded,
                  title: 'DEVICE CONNECTIONS',
                ),
                const SizedBox(height: 16),
                _DeviceConnectionTile(
                  icon: Icons.memory_rounded,
                  name: 'Raspberry Pi',
                  detail: widget.controller.piConnected
                      ? 'Connected to ${widget.controller.piAddress}'
                      : 'Connect over local Wi-Fi',
                  connected: widget.controller.piConnected,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: widget.controller.piConnected
                        ? widget.controller.disconnectPi
                        : () => widget.controller.connectPi(address.text),
                    icon: Icon(
                      widget.controller.piConnected
                          ? Icons.link_off
                          : Icons.wifi_rounded,
                    ),
                    label: Text(
                      widget.controller.piConnected
                          ? 'Disconnect Raspberry Pi'
                          : 'Connect Raspberry Pi',
                    ),
                  ),
                ),
                const Divider(height: 30),
                _DeviceConnectionTile(
                  icon: Icons.bluetooth_rounded,
                  name: 'RobotDog-Control',
                  detail: widget.controller.esp32Connected
                      ? 'ESP32 Bluetooth ready'
                      : 'Keep the robot powered on and nearby',
                  connected: widget.controller.esp32Connected,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: widget.controller.esp32Connected
                        ? widget.controller.disconnectEsp32
                        : widget.controller.connectEsp32,
                    icon: Icon(
                      widget.controller.esp32Connected
                          ? Icons.bluetooth_disabled
                          : Icons.bluetooth_searching,
                    ),
                    label: Text(
                      widget.controller.esp32Connected
                          ? 'Disconnect ESP32'
                          : 'Scan & connect ESP32',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Safety: test movement with the robot lifted securely. Emergency Stop sends OFF to ESP32 and stop_move to Raspberry Pi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF929BB1), fontSize: 12),
        ),
      ],
    );

    if (!widget.firstRun) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('THUTA AI SETUP')),
      body: SafeArea(child: content),
    );
  }
}

class _ControlHeader extends StatelessWidget {
  const _ControlHeader();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF7557D5),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        child: Padding(
          padding: EdgeInsets.all(11),
          child: Icon(Icons.smart_toy_rounded, color: Colors.white),
        ),
      ),
      SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ROBOT COMMAND CENTER',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manual control & live systems',
              style: TextStyle(color: Color(0xFF929BB1)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.label, required this.connected});
  final String label;
  final bool connected;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Chip(
      avatar: CircleAvatar(
        backgroundColor: connected ? Colors.greenAccent : Colors.grey,
        radius: 5,
      ),
      label: Text(label),
    ),
  );
}

class _RobotStrip extends StatelessWidget {
  const _RobotStrip({required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            child: Text('🐶', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.robot.emotion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  '${controller.robot.status} • ${controller.robot.action}',
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text('${controller.robot.energy}%'),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;
  @override
  Widget build(BuildContext context) {
    final user = message.role == ChatRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: user
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF292536),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(message.text),
      ),
    );
  }
}

class _ConnectionCard extends StatefulWidget {
  const _ConnectionCard({required this.controller});
  final AppController controller;
  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard> {
  late final TextEditingController address = TextEditingController(
    text: widget.controller.piAddress,
  );
  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(icon: Icons.hub_outlined, title: 'CONNECTIONS'),
          const SizedBox(height: 16),
          _DeviceConnectionTile(
            icon: Icons.memory_rounded,
            name: 'Raspberry Pi',
            detail: widget.controller.piConnected
                ? 'AI brain online'
                : 'AI brain offline',
            connected: widget.controller.piConnected,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: address,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'raspberrypi.local:8000',
              prefixIcon: const Icon(Icons.lan_outlined, size: 20),
              filled: true,
              fillColor: const Color(0xFF0D111B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => widget.controller.connectPi(address.text),
              icon: const Icon(Icons.wifi_rounded),
              label: Text(
                widget.controller.piConnected
                    ? 'Reconnect Pi'
                    : 'Connect Raspberry Pi',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _DeviceConnectionTile(
            icon: Icons.bluetooth_rounded,
            name: 'ESP32 Robot',
            detail: widget.controller.esp32Connected
                ? 'RobotDog-Control ready'
                : 'Bluetooth disconnected',
            connected: widget.controller.esp32Connected,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: widget.controller.connectEsp32,
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(
                widget.controller.esp32Connected
                    ? 'Reconnect ESP32'
                    : 'Find RobotDog',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.mode,
    required this.speed,
    required this.onMode,
    required this.onCommand,
    required this.onSpeed,
  });
  final String mode;
  final int speed;
  final Future<void> Function(String) onMode;
  final Future<void> Function(String) onCommand;
  final ValueChanged<double> onSpeed;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionLabel(
            icon: Icons.sports_esports_rounded,
            title: 'DRIVE CONTROL',
          ),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: 'CMD',
                label: Text(
                  'MANUAL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              ButtonSegment(
                value: 'SEARCH',
                label: Text(
                  'AUTO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              ButtonSegment(
                value: 'OFF',
                label: Text(
                  'OFF',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (value) => onMode(value.first),
          ),
          const SizedBox(height: 24),
          _DrivePad(onCommand: onCommand),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: Color(0xFFA996FF)),
              const SizedBox(width: 9),
              const Text(
                'Drive speed',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF29223F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    '$speed PWM',
                    style: const TextStyle(
                      color: Color(0xFFBCAEFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: speed.toDouble(),
            min: 120,
            max: 180,
            divisions: 12,
            onChanged: onSpeed,
          ),
        ],
      ),
    ),
  );
}

class _DrivePad extends StatelessWidget {
  const _DrivePad({required this.onCommand});
  final Future<void> Function(String) onCommand;
  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    height: 250,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF0B0F18),
      border: Border.all(color: const Color(0xFF30384D), width: 2),
      boxShadow: const [BoxShadow(color: Color(0x337C5CFF), blurRadius: 34)],
    ),
    child: Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: _DriveButton(
            icon: Icons.keyboard_arrow_up_rounded,
            label: 'FORWARD',
            onTap: () => onCommand('FORWARD'),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _DriveButton(
            icon: Icons.keyboard_arrow_left_rounded,
            label: 'LEFT',
            onTap: () => onCommand('LEFT'),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: _DriveButton(
            icon: Icons.keyboard_arrow_right_rounded,
            label: 'RIGHT',
            onTap: () => onCommand('RIGHT'),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _DriveButton(
            icon: Icons.keyboard_arrow_down_rounded,
            label: 'BACK',
            onTap: () => onCommand('BACKWARD'),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: InkWell(
            onTap: () => onCommand('STOP'),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5C68), Color(0xFFB8172D)],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x66FF334D), blurRadius: 20),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_rounded, color: Colors.white, size: 27),
                  Text(
                    'STOP',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DriveButton extends StatelessWidget {
  const _DriveButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: 68,
      height: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFA996FF), size: 31),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF8E97AC),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.monitor_heart_outlined,
            title: 'LIVE TELEMETRY',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'EMOTION',
                  value: controller.robot.emotion,
                  icon: Icons.mood_rounded,
                  color: const Color(0xFFFFB85C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'ENERGY',
                  value: '${controller.robot.energy}%',
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF59DF9B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Metric(
            label: 'CURRENT ACTION',
            value: controller.robot.action,
            icon: Icons.directions_run_rounded,
            color: const Color(0xFFA996FF),
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFF0D111B),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF737D93),
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: const Color(0xFFA996FF)),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    ],
  );
}

class _DeviceConnectionTile extends StatelessWidget {
  const _DeviceConnectionTile({
    required this.icon,
    required this.name,
    required this.detail,
    required this.connected,
  });
  final IconData icon;
  final String name;
  final String detail;
  final bool connected;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF25203A),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: const Color(0xFFB4A5FF)),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFF858FA5), fontSize: 12),
            ),
          ],
        ),
      ),
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: connected ? const Color(0xFF58E39B) : const Color(0xFF606A80),
          boxShadow: connected
              ? const [BoxShadow(color: Color(0x8858E39B), blurRadius: 8)]
              : null,
        ),
      ),
    ],
  );
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFD7263D),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: const Icon(Icons.warning_amber_rounded, size: 26),
      label: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EMERGENCY STOP',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          Text(
            'Immediately stops Pi and ESP32 control',
            style: TextStyle(fontSize: 10, color: Color(0xFFFFD6DB)),
          ),
        ],
      ),
    ),
  );
}
