# PiRowFlo Control

Flutter-based Android companion app for **PiRowFlo** and **SmartRow**.

PiRowFlo Control combines PiRowFlo control, structured rowing workouts, SmartRow live metrics, Nextcloud-based workout planning and Endurain statistics in a single Android app.

The app communicates with the [PiRowFlo Control API](https://github.com/stampede79/pirowflo-control-api). SmartRow remains connected to PiRowFlo; the Android app receives normalized live metrics through the Control API instead of establishing a second Bluetooth connection.

**Current release:** v0.1.0

---

## Screenshots

<p align="center">
  <img src="docs/screenshots/home.png" width="280" alt="PiRowFlo Control overview">
  &nbsp;&nbsp;
  <img src="docs/screenshots/training.png" width="280" alt="Workout planning">
</p>

<p align="center">
  <img src="docs/screenshots/live-workout.png" width="280" alt="Live workout">
  &nbsp;&nbsp;
  <img src="docs/screenshots/step-preview.png" width="280" alt="Workout step preview">
</p>

<p align="center">
  <img src="docs/screenshots/statistics.png" width="280" alt="Rowing statistics">
  &nbsp;&nbsp;
  <img src="docs/screenshots/activity-detail.png" width="280" alt="Activity details">
</p>

---

## Features

### PiRowFlo control

The app provides a mobile interface for controlling a PiRowFlo installation.

Supported functions include:

- Display the currently active PiRowFlo operating mode
- Display SmartRow connection and readiness state
- Start PiRowFlo in:
  - Bluetooth + ANT+ mode
  - Bluetooth-only mode
  - ANT+-only mode
- Restart PiRowFlo
- Stop PiRowFlo
- Reset the current SmartRow training session
- Configure the PiRowFlo server and API key
- Configure the app using a QR code

The control screen only displays the currently active operating mode. Available mode switches are shown as actions below it.

---

### SmartRow live metrics

During a workout the app displays live SmartRow data provided by PiRowFlo:

- Power in watts
- Stroke rate (SPM)
- Pace per 500 m
- Distance
- SmartRow connection and readiness state

The workout screen polls the PiRowFlo Control API for live metrics while PiRowFlo continues to handle the actual SmartRow connection and its Bluetooth / FTMS and ANT+ outputs.

This allows the app to use SmartRow data without requiring another direct Bluetooth connection to SmartRow.

---

### Power target guidance

Workout steps can define target ranges for power, stroke rate and pace.

For configured power targets, the current SmartRow power value is color-coded:

- Green: inside the target range
- Orange: up to 5% outside the target range
- Red: more than 5% outside the target range

The displayed watt value always represents the current SmartRow measurement.

---

## Nextcloud training calendar

PiRowFlo Control can load planned workouts from a **Nextcloud calendar using CalDAV**.

The app supports:

- Today's runnable workouts
- Multiple PiRowFlo workouts on the same day
- Upcoming workouts
- Calendar connection testing
- Structured workout definitions embedded in normal calendar descriptions

The following settings are stored securely on the Android device:

- CalDAV calendar URL
- Nextcloud username
- Nextcloud app password

Calendar events without a valid `[PIROWFLO]` block are not treated as runnable workouts.

### Workout definition format

A normal calendar description can contain a machine-readable block:

```text
[PIROWFLO]
warmup=7m
repeat=5
work=3m,135-145w
recovery=2m,90-100w
cooldown=5m
[/PIROWFLO]
```

This produces:

```text
7 min warm-up

5 x:
  3 min at 135-145 W
  2 min at 90-100 W

5 min cool-down
```

Stroke-rate targets can be added:

```text
[PIROWFLO]
warmup=5m
work=40m,105-110w,16-18spm
cooldown=5m
[/PIROWFLO]
```

Workout steps can contain combinations of:

- Duration
- Power target
- Stroke-rate target
- Pace target

---

## Guided workout runner

Structured workouts are executed step by step.

The live workout screen provides:

- Current workout step
- Remaining step time
- Step progress
- Current SmartRow power
- Target power
- Stroke rate
- Pace
- Distance
- SmartRow live/offline state
- Pause and resume
- Manual step skipping

The Android display is kept awake while the workout screen is open.

### Step preview and countdown

Before the first workout step starts, PiRowFlo Control displays a large **3-2-1 pre-start overlay**.

The overlay shows the upcoming step together with its configured targets, for example:

```text
FIRST STEP

WARM-UP

80-90 W
16-18 SPM

7:00

3
```

Before subsequent step transitions, the same mechanism displays the **next workout step**.

Depending on the workout definition, the preview can show:

- Power target
- Stroke-rate target
- Pace target
- Step duration
- Step type
- Step title

The preview is designed to remain readable while rowing and disappears automatically when the new step begins.

Resuming a paused workout does not trigger another pre-start countdown.

---

## Audio cues

The workout runner provides audio feedback so the display does not need to be watched continuously.

Audio feedback includes:

- Countdown signals at 3, 2 and 1 seconds
- Separate signal when a work interval begins
- Separate signal when a recovery, warm-up or cool-down begins
- Completion signal when the workout finishes

---

## Workout recording

SmartRow metrics are recorded for each workout step while the workout is running.

Each step result includes:

- Actual duration
- Average power
- Average stroke rate
- Average pace
- Distance
- Percentage of active power samples inside the configured target range

Zero-power / idle samples are excluded from power target evaluation.

After the final step, the app displays individual step results and an overall workout summary.

The overall summary includes:

- Total training time
- Total distance
- Average power
- Average stroke rate
- Average pace
- Overall percentage inside configured power target ranges

Workout runner results are currently kept in memory and are not persisted by PiRowFlo Control itself.

---

## Endurain integration

PiRowFlo Control can connect to an **Endurain** instance for historical rowing data and statistics.

The integration supports authentication using Endurain access and refresh tokens. Expired access tokens are automatically refreshed when possible.

### Rowing statistics

Indoor rowing statistics can be displayed for:

- Week
- Month
- Year
- Lifetime

Available summary values include:

- Total distance
- Training duration
- Activity count
- Calories
- Distance development over the selected period

### Activity history

The app provides a separate list of recent indoor rowing activities.

Each activity can be opened to display detailed values such as:

- Distance
- Duration
- Average pace
- Average power
- Maximum power
- Normalized power
- Average stroke rate
- Maximum stroke rate
- Stroke count
- Average heart rate
- Maximum heart rate
- Calories

### Activity stream charts

When available from Endurain, PiRowFlo Control displays synchronized charts for:

- Power
- Stroke rate
- Heart rate

All charts use a common activity timeline so that events in different streams can be compared directly.

For visualization, the app performs conservative stream preparation including:

- Detection of a stable activity start
- Removal of obvious short measurement spikes where appropriate
- Median filtering for small measurement artifacts
- Downsampling for efficient chart rendering

This processing only affects chart presentation. The original Endurain activity data is not modified.

---

## Architecture

```text
                         Nextcloud
                            |
                            | CalDAV
                            v
                   PiRowFlo Control App
                     /             \
                    /               \
          HTTP / REST                \ Endurain API
                  /                   \
                 v                     v
       PiRowFlo Control API        Endurain
                 |                    |
        +--------+--------+           |
        |                 |           |
 Supervisor control    Unix socket    +--> Activities
                          |            +--> Statistics
                          |            +--> Streams
                          v
                       PiRowFlo
                          |
              +-----------+-----------+
              |           |           |
           SmartRow   Bluetooth /    ANT+
                       FTMS
              |
              v
         Live metrics
              |
              +----> Control API ----> App
```

SmartRow remains connected to PiRowFlo. The Android app does not connect directly to SmartRow.

This keeps the existing PiRowFlo Bluetooth / FTMS and ANT+ data paths independent from the workout UI.

---

## Components

The components are maintained in separate repositories:

- [PiRowFlo](https://github.com/stampede79/pirowflo)
- [PiRowFlo Control API](https://github.com/stampede79/pirowflo-control-api)
- [PiRowFlo Control App](https://github.com/stampede79/pirowflo-control-app)

For a complete Raspberry Pi installation, see:

- [PiRowFlo Installer](https://github.com/stampede79/pirowflo-installer)

---

## Requirements

To build the app you need:

- Flutter 3.47.2 or a compatible newer version
- Dart 3.13.2 or a compatible newer version
- Android SDK
- Java / JDK required by the installed Flutter version
- Git
- Android device or emulator

Check the Flutter environment with:

```bash
flutter doctor
```

Resolve any reported Android toolchain issues before building the app.

---

## Clone the repository

```bash
git clone https://github.com/stampede79/pirowflo-control-app.git
cd pirowflo-control-app
flutter pub get
```

---

## Development

Check the project with:

```bash
flutter analyze
flutter test
```

### Development flavor

PiRowFlo Control provides separate development and production Android flavors.

The development version can be installed alongside the production version and uses separate app data.

Build the development APK with:

```bash
flutter build apk \
  --flavor dev \
  --debug
```

The Android launcher identifies this build as:

```text
PiRowFlo-Controller Dev
```

---

## Build a production APK

The production Android launcher name is:

```text
PiRowFlo-Controller
```

For an ARM64 production release:

```bash
flutter build apk \
  --flavor prod \
  --release \
  --target-platform android-arm64
```

Result:

```text
build/app/outputs/flutter-apk/app-prod-release.apk
```

Building only ARM64 significantly reduces APK size compared with a multi-architecture APK and is suitable for modern ARM64 Android devices.

The current release uses:

```text
Version:      0.1.0
Version code: 1
```

The version is defined in `pubspec.yaml`:

```yaml
version: 0.1.0+1
```

The app displays its installed version in the navigation drawer.

---

## Install using ADB

For a connected Android device:

```bash
adb install -r \
  build/app/outputs/flutter-apk/app-prod-release.apk
```

The APK can alternatively be copied to the Android device and installed manually.

---

## App configuration

Open **Settings** from the navigation drawer.

### PiRowFlo server

Enter the complete base URL of the PiRowFlo Control API including protocol and port.

Example:

```text
http://192.168.178.123:8090
```

Do not append `/api/status`, `/api/metrics` or another API path.

### API key

The Control API uses an API key sent by the app using the `X-API-Key` HTTP header.

The key is configured on the PiRowFlo host through the Control API environment configuration.

The server address and API key are stored locally using Flutter Secure Storage.

Keep the API key private.

### Nextcloud calendar

Configure:

- CalDAV calendar URL
- Nextcloud username
- Nextcloud app password

Example:

```text
https://cloud.example.com/remote.php/dav/calendars/USER/training/
```

Use a dedicated Nextcloud app password instead of the normal account password.

The app provides a calendar connection test before using the configuration for workouts.

### Endurain

Configure the Endurain server and credentials from the app settings.

After a successful login, PiRowFlo Control stores the authentication tokens securely and uses them for statistics and activity retrieval.

When an access token expires, the app attempts to refresh the session automatically.

---

## PiRowFlo Control API

The app uses endpoints including:

```text
GET  /api/status
GET  /api/metrics

POST /api/start/combined
POST /api/start/bluetooth
POST /api/start/ant
POST /api/restart
POST /api/reset
POST /api/stop
```

`/api/metrics` exposes normalized SmartRow live data such as:

```json
{
  "smartrow_connected": true,
  "smartrow_ready": true,
  "rowing": true,
  "power_w": 139,
  "stroke_rate_spm": 24,
  "pace_500m_seconds": 139,
  "distance_m": 1240,
  "elapsed_seconds": 420
}
```

---

## Troubleshooting

### App cannot reach PiRowFlo

Verify that the Control API is running:

```bash
systemctl status pirowflo-control.service
```

Check that port `8090` is reachable from the Android device.

### SmartRow is offline

The app distinguishes between the Control API being reachable and SmartRow being connected.

Check PiRowFlo:

```bash
/opt/pirowflo/venv/bin/supervisorctl \
  -c /opt/pirowflo/services/supervisord.conf \
  status
```

Check the PiRowFlo log:

```bash
tail -n 100 /opt/pirowflo/src/pirowflo.log
```

### Nextcloud calendar cannot be accessed

Verify:

- The CalDAV URL
- Network connectivity to Nextcloud
- Nextcloud username
- Nextcloud app password

A working CalDAV calendar should respond successfully to an authenticated `PROPFIND` request.

### No live workout values

Verify:

1. PiRowFlo is running.
2. SmartRow is connected.
3. SmartRow services are resolved.
4. `/api/metrics` is reachable.
5. The API key is correct.

### Endurain statistics cannot be loaded

Verify:

- Endurain is reachable from the Android device
- The configured Endurain server is correct
- Authentication is valid
- The Endurain session can be refreshed if the access token has expired

---

## Current limitations / planned work

The following areas are not implemented or are candidates for future development:

- Persisting PiRowFlo workout-runner results
- Synchronizing completed planned workouts back to Nextcloud
- Linking a planned PiRowFlo workout with the corresponding completed Endurain activity
- Additional long-term performance trends
- Additional workout result visualizations
- Optional improvements to live target feedback
- Garmin Connect IQ integration

---

## Related projects

- [PiRowFlo](https://github.com/stampede79/pirowflo)
- [PiRowFlo Control API](https://github.com/stampede79/pirowflo-control-api)
- [PiRowFlo Installer](https://github.com/stampede79/pirowflo-installer)
