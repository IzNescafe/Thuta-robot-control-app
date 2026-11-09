# Thuta AI Flutter App Setup Guide

ဒီလမ်းညွှန်က Thuta AI RobotDog app ကို Windows laptop မှာ ပြင်ဆင်ခြင်း၊
စမ်းသပ်ခြင်းနဲ့ Android/iOS device တွေမှာ အသုံးပြုခြင်းအတွက် ဖြစ်ပါတယ်။

## 1. Project နဲ့ Flutter SDK နေရာ

Project folder:

```text
C:\Users\user\OneDrive\Documents\robot dog\robot dog control app\robot_dog_app
```

Flutter SDK:

```text
C:\Users\user\OneDrive\Documents\robot dog\robot dog control app\flutter
```

Flutter ကို Windows `PATH` ထဲမထည့်ထားသေးတာကြောင့် ဒီ project မှာ command
တိုင်းကို `..\flutter\bin\flutter.bat` လမ်းကြောင်းနဲ့ အသုံးပြုပါမယ်။

## 2. Project ကို VS Code မှာဖွင့်ခြင်း

1. VS Code ဖွင့်ပါ။
2. **File > Open Folder** ကိုနှိပ်ပါ။
3. `robot_dog_app` folder ကိုရွေးပါ။
4. **Terminal > New Terminal** ကိုနှိပ်ပါ။

Terminal က မှန်ကန်တဲ့ folder မှာမရှိရင်:

```powershell
cd "C:\Users\user\OneDrive\Documents\robot dog\robot dog control app\robot_dog_app"
```

## 3. Flutter packages ပြင်ဆင်ခြင်း

Project ကိုပထမဆုံး run ခြင်း သို့မဟုတ် `pubspec.yaml` ပြောင်းပြီးတိုင်း:

```powershell
& "..\flutter\bin\flutter.bat" pub get
```

Flutter installation စစ်ရန်:

```powershell
& "..\flutter\bin\flutter.bat" doctor
```

## 4. Laptop Chrome မှာ App စမ်းခြင်း

```powershell
& "..\flutter\bin\flutter.bat" run -d chrome
```

သို့မဟုတ် clean release preview ကိုဖွင့်ရန်:

```powershell
powershell -ExecutionPolicy Bypass -File ".\run_laptop.ps1"
```

`web/index.html` ကို double-click မလုပ်ပါနဲ့။ အဲဒီဖိုင်က compiled app မဟုတ်ဘဲ
Flutter web template ဖြစ်ပါတယ်။

## 5. iPhone သို့မဟုတ် အခြားဖုန်းက browser ဖြင့် စမ်းခြင်း

Laptop နဲ့ ဖုန်းကို Wi-Fi တစ်ခုတည်းချိတ်ပြီး:

```powershell
& "..\flutter\bin\flutter.bat" run -d web-server --web-hostname 0.0.0.0 --web-port 8181
```

PowerShell window အသစ်မှာ Laptop IP ရှာပါ:

```powershell
ipconfig
```

`Wireless LAN adapter Wi-Fi` အောက်က `IPv4 Address` ကိုရှာပါ။ ဥပမာ
`192.168.1.25` ဆိုရင် ဖုန်း Safari/Chrome မှာ:

```text
http://192.168.1.25:8181
```

ဖွင့်ပါ။ Windows Firewall မေးလာရင် **Private networks > Allow access** ကို
ရွေးပါ။ Server ပိတ်ရန် terminal ထဲမှာ `q` သို့မဟုတ် `Ctrl+C` နှိပ်ပါ။

> iPhone Safari web version က Raspberry Pi WebSocket ကို အသုံးပြုနိုင်ပေမယ့်
> ESP32 BLE ကို တိုက်ရိုက်မချိတ်နိုင်ပါ။ ESP32 BLE အတွက် native iOS app လိုပါတယ်။

## 6. App ပထမဆုံး Setup

App ပထမဆုံးဖွင့်တဲ့အခါ **Add your RobotDog** screen ပေါ်လာပါမယ်။

1. **Robot name** မှာ `Thuta` ထည့်ပါ။
2. **Raspberry Pi address** မှာ `raspberrypi.local:8000` ထည့်ပါ။
3. **Save & continue** ကိုနှိပ်ပါ။
4. အောက်က **Setup** tab ကိုဖွင့်ပါ။
5. **Connect Raspberry Pi** ကိုနှိပ်ပါ။
6. Robot ကို power ဖွင့်ပြီး **Scan & connect ESP32** ကိုနှိပ်ပါ။

`raspberrypi.local` မရရင် Pi terminal မှာ `hostname -I` run ပြီး IPv4 address
ကိုသုံးပါ။ ဥပမာ:

```text
192.168.1.30:8000
```

## 7. Android ဖုန်းမှာ စမ်းခြင်း

Android ဖုန်းမှာ:

1. **Developer options** ဖွင့်ပါ။
2. **USB debugging** ဖွင့်ပါ။
3. USB cable နဲ့ laptop ကိုချိတ်ပါ။
4. ဖုန်းပေါ်က debugging permission ကို Allow လုပ်ပါ။

Device တွေ့မတွေ့စစ်ရန်:

```powershell
& "..\flutter\bin\flutter.bat" devices
```

Android ဖုန်းမှာ app run ရန်:

```powershell
& "..\flutter\bin\flutter.bat" run
```

Bluetooth permission မေးလာရင် **Nearby devices/Bluetooth** permission ကို
Allow လုပ်ပါ။ Android version အဟောင်းမှာ Location permission လည်းလိုနိုင်ပါတယ်။

## 8. Android APK ထုတ်ခြင်း

Debug APK:

```powershell
& "..\flutter\bin\flutter.bat" build apk --debug
```

ထွက်လာမယ့်ဖိုင်:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

Release APK:

```powershell
& "..\flutter\bin\flutter.bat" build apk --release
```

Google Play Store အတွက် Android App Bundle:

```powershell
& "..\flutter\bin\flutter.bat" build appbundle --release
```

Play Store release မတင်မီ signing key နဲ့ release signing configuration ကို
သီးခြားပြင်ဆင်ရပါမယ်။

## 9. Native iOS App ထုတ်ခြင်း

Windows ကနေ native iOS app ကို build/sign လုပ်လို့မရပါ။ အောက်ပါတို့လိုပါတယ်:

- Mac computer
- Xcode
- Apple ID
- Physical iPhone
- App Store တင်ရန် Apple Developer Program membership

Project ကို Mac ထဲကူးပြီး:

```bash
cd robot_dog_app
flutter pub get
open ios/Runner.xcworkspace
```

Xcode ထဲမှာ **Runner > Signing & Capabilities** ကိုဖွင့်ပြီး Apple Team နဲ့
unique Bundle Identifier ကိုရွေးပါ။ ပြီးနောက် iPhone ကို device အဖြစ်ရွေးပြီး
Run နှိပ်ပါ။

Project ထဲမှာ Bluetooth နဲ့ local-network permission descriptions ထည့်ထားပြီးသား
ဖြစ်ပေမယ့် native iPhone နဲ့ BLE/Pi connection ကို hardware ပေါ်မှာ စမ်းသပ်ရပါမယ်။

## 10. Raspberry Pi ကို Laptop မလိုဘဲ Host လုပ်ခြင်း

Pi setup နဲ့ boot-time service installer လမ်းညွှန်ကို ဒီဖိုင်မှာကြည့်ပါ:

```text
pi_server/RASPBERRY_PI_SETUP.md
```

Pi service အလုပ်လုပ်ရင် mobile app က Pi ရဲ့ port `8000` ကို local Wi-Fi မှတစ်ဆင့်
တိုက်ရိုက်ဆက်သွယ်ပါတယ်။ Laptop host မလိုတော့ပါ။

## 11. Safety

- ပထမဆုံး movement test မှာ robot ကို မြေပြင်ပေါ်မထားဘဲ လုံခြုံစွာမြှောက်ထားပါ။
- Servo/motor power ကို Raspberry Pi/ESP32 logic power နဲ့ မရောပါနဲ့။
- Raspberry Pi GPIO က 3.3 V logic ဖြစ်လို့ 5 V signal ကို တိုက်ရိုက်မထည့်ပါနဲ့။
- အန္တရာယ်ရှိတဲ့ motion ဖြစ်ရင် App ထဲက **EMERGENCY STOP** ကိုနှိပ်ပါ။
- App source/build အောင်မြင်တာဟာ physical robot motion အောင်မြင်ကြောင်း မဆိုလိုပါ။

## 12. Common Errors

### `flutter is not recognized`

Bare `flutter` မသုံးဘဲ:

```powershell
& "..\flutter\bin\flutter.bat" doctor
```

### `Flutter SDK was not found`

ဒီဖိုင်ရှိမရှိ စစ်ပါ:

```powershell
Test-Path "..\flutter\bin\flutter.bat"
```

`True` မပေါ်ရင် Flutter SDK folder ပျောက်နေခြင်း သို့မဟုတ် နေရာရွှေ့ထားခြင်း
ဖြစ်ပါတယ်။

### Phone မှာ web page မပေါ်ခြင်း

- Laptop နဲ့ phone က Wi-Fi တစ်ခုတည်းဖြစ်ရမယ်။
- Server ကို `--web-hostname 0.0.0.0` နဲ့ run ထားရမယ်။
- `localhost` အစား Laptop IPv4 address ကို ဖုန်းမှာသုံးရမယ်။
- Windows Firewall မှာ Private network access ခွင့်ပြုရမယ်။

### Raspberry Pi မချိတ်နိုင်ခြင်း

- Pi နဲ့ phone က Wi-Fi တစ်ခုတည်းရှိမရှိစစ်ပါ။
- Pi မှာ `curl http://127.0.0.1:8000/health` စစ်ပါ။
- App address မှာ `http://` မလိုပါ။ `raspberrypi.local:8000` သို့မဟုတ်
  `<Pi IPv4>:8000` ကိုသုံးပါ။

### ESP32 BLE မတွေ့ခြင်း

- Robot power ဖွင့်ထားပါ။
- Phone Bluetooth ဖွင့်ထားပါ။
- App Bluetooth/Nearby Devices permissions ခွင့်ပြုပါ။
- ESP32 firmware က `RobotDog-Control` အမည်နဲ့ advertise လုပ်နေကြောင်းစစ်ပါ။
- Web browser မဟုတ်ဘဲ native Android/iOS app နဲ့စမ်းပါ။
