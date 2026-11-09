# robot_dog_app

Full beginner setup guide: [`FLUTTER_APP_SETUP.md`](FLUTTER_APP_SETUP.md)

## View on this laptop

Do not double-click `web/index.html`; it is a Flutter source template and does
not contain the compiled application. Open PowerShell in this project and run:

```powershell
.\run_laptop.ps1
```

The script builds the Flutter web app, starts a clean local server, and opens it
in the default browser. Keep the terminal open and press Enter in it to stop the
preview. This viewer mode avoids Flutter debug-inspector messages in Chrome.

Alternatively, double-click `START_THUTA_APP.bat` in File Explorer. The batch
launcher runs the PowerShell script with the correct execution policy.

## Mobile app features

- First-run **Add RobotDog** onboarding
- Saved robot name and Raspberry Pi address
- Raspberry Pi WebSocket connection over local Wi-Fi
- ESP32 BLE connection to `RobotDog-Control`
- Chat, telemetry, drive controls, reconnect/disconnect, and emergency stop
- **Safety & Alert Center** prototype with an arm/pause switch, obstacle/cliff,
  battery, connection, and unknown-face alert rules
- **Face Recognition** prototype with camera-stream state, recognition toggle,
  enrollment entry point, privacy guidance, and a results area

The saved connection profile removes repeated address entry. Bluetooth and Pi
connections are intentionally re-established when the app/device restarts.

The new alert and face-recognition screens are UI prototypes. They show the
intended user experience, but still need Pi-side camera/recognition and alert
services before they can deliver real notifications or identify people.

## Raspberry Pi always-on service

See [`pi_server/RASPBERRY_PI_SETUP.md`](pi_server/RASPBERRY_PI_SETUP.md). The
installer configures a boot-time `systemd` service so the Pi, rather than a
laptop, hosts the robot bridge.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
