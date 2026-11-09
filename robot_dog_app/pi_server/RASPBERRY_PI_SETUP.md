# Raspberry Pi setup

This installs the Thuta WebSocket bridge as a `systemd` service. It starts at
boot, listens on port `8000`, and keeps the mobile app independent of a laptop.

## 1. Copy the folders to the Pi

Copy both `Thuta-Code-Updated` and this `pi_server` folder to the Raspberry Pi.
The AI model file expected by the current brain code is:

```text
Thuta-Code-Updated/models/llm/thuta_model_q4_k_m.gguf
```

## 2. Enable Raspberry Pi UART

Run `sudo raspi-config`, choose **Interface Options > Serial Port**, disable the
login shell over serial, and enable the serial hardware. Reboot afterward.

## 3. Install the service

From the copied `pi_server` folder, run:

```bash
bash install_pi_service.sh /home/pi/Thuta-Code-Updated
```

Replace `/home/pi/Thuta-Code-Updated` with its real absolute path.

## 4. Verify it

```bash
sudo systemctl status thuta-ai.service
curl http://127.0.0.1:8000/health
hostname -I
```

The health response should contain `"ok": true`. In the mobile app, use
`raspberrypi.local:8000` or `<Pi IPv4 address>:8000`.

## 5. Troubleshoot

```bash
journalctl -u thuta-ai.service -f
sudo systemctl restart thuta-ai.service
```

If `uart` is false, verify `/dev/ttyAMA2`, the Pi UART configuration, wiring,
and permission to access the serial device. Do not connect 5 V logic directly
to Raspberry Pi GPIO pins.
