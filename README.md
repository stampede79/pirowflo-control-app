# PiRowFlo Control

Flutter-based Android control app for PiRowFlo.

PiRowFlo Control provides a simple mobile interface for starting, stopping and
monitoring a PiRowFlo installation. It communicates with the
[PiRowFlo Control API](https://github.com/stampede79/pirowflo-control-api).

<p align="center">
  <img src="docs/screenshots/main-screen.png"
       alt="PiRowFlo Control main screen"
       width="320">
</p>

## Features

- Display the current PiRowFlo status
- Display the SmartRow connection status
- Start PiRowFlo in different modes:
  - Bluetooth + ANT+
  - Bluetooth only
  - ANT+ only
- Restart PiRowFlo
- Stop PiRowFlo
- Reset the current training session
- Configure the PiRowFlo server and API key

## Architecture

```text
PiRowFlo Control App
        |
        | HTTP / REST
        v
PiRowFlo Control API
        |
        | Supervisor / control socket
        v
PiRowFlo
        |
        +---- SmartRow
        |
        +---- Bluetooth / FTMS
        |
        +---- ANT+
```

The three components are maintained in separate repositories:

- PiRowFlo  
  https://github.com/stampede79/pirowflo
- PiRowFlo Control API  
  https://github.com/stampede79/pirowflo-control-api
- PiRowFlo Control App  
  https://github.com/stampede79/pirowflo-control-app

For a complete Raspberry Pi installation, see:

https://github.com/stampede79/pirowflo-installer

## Requirements

To build the app you need:

- Flutter 3.47.2 or a compatible newer version
- Dart 3.13.2 or a compatible newer version
- Android SDK
- Java / JDK required by the installed Flutter version
- Git
- an Android device or emulator

Check your Flutter environment with:

```bash
flutter doctor
```

Resolve any reported Android toolchain issues before building the app.

## Clone the repository

```bash
git clone https://github.com/stampede79/pirowflo-control-app.git
cd pirowflo-control-app
```

Install the Flutter dependencies:

```bash
flutter pub get
```

## Run in development mode

Connect an Android device with USB debugging enabled or start an Android
emulator.

Check that Flutter can see the device:

```bash
flutter devices
```

Then start the app:

```bash
flutter run
```

## Build an Android APK

Create a release APK with:

```bash
flutter build apk --release
```

The resulting APK can be found at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Install the APK

### Using ADB

With an Android device connected:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Manual installation

Alternatively, copy

```text
build/app/outputs/flutter-apk/app-release.apk
```

to the Android device and open the APK there.

Android may ask for permission to install apps from the application used to
open the APK.

## App configuration

Open the settings using the gear icon in the upper-right corner.

### Server

Enter the complete base URL of the PiRowFlo Control API including the protocol
and port.

Example:

```text
http://192.168.178.123:8090
```

Do not append `/api/status` or another API path. The app adds the required API
paths automatically.

### API key

Enter the API key generated during installation of the PiRowFlo Control API.

On the PiRowFlo host, the configured key can be displayed with:

```bash
sudo grep '^PIROWFLO_API_KEY=' /etc/pirowflo-control.env
```

The app sends the key using the `X-API-Key` HTTP header.

The server address and API key are stored locally using Flutter Secure Storage.

Keep the API key private.

## PiRowFlo modes

### Bluetooth + ANT+

Starts PiRowFlo with both FTMS Bluetooth broadcasting and ANT+ enabled.

This is the normal combined mode.

### Bluetooth

Starts PiRowFlo with FTMS Bluetooth broadcasting only.

### ANT+

Starts PiRowFlo with ANT+ broadcasting only.

## Troubleshooting

### App cannot reach PiRowFlo

Verify that the Control API is running:

```bash
systemctl status pirowflo-control.service
```

Check that port `8090` is reachable from the Android device.

### Authentication fails

Verify that the API key configured in the app matches:

```bash
sudo grep '^PIROWFLO_API_KEY=' /etc/pirowflo-control.env
```

### PiRowFlo does not start

Check the Supervisor status:

```bash
/opt/pirowflo/venv/bin/supervisorctl \
  -c /opt/pirowflo/services/supervisord.conf \
  status
```

Check the PiRowFlo log:

```bash
tail -n 100 /opt/pirowflo/src/pirowflo.log
```

## Related projects

- [PiRowFlo](https://github.com/stampede79/pirowflo)
- [PiRowFlo Control API](https://github.com/stampede79/pirowflo-control-api)
- [PiRowFlo Installer](https://github.com/stampede79/pirowflo-installer)
