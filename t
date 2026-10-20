[1mdiff --git a/README.md b/README.md[m
[1mindex 2fc3c71..bfa28f5 100644[m
[1m--- a/README.md[m
[1m+++ b/README.md[m
[36m@@ -1,9 +1,12 @@[m
 # PiRowFlo Control[m
 [m
[31m-Flutter-based Android control app for PiRowFlo.[m
[32m+[m[32mFlutter-based Android companion app for PiRowFlo and SmartRow.[m
 [m
[31m-PiRowFlo Control provides a simple mobile interface for starting, stopping and[m
[31m-monitoring a PiRowFlo installation. It communicates with the[m
[32m+[m[32mPiRowFlo Control provides a mobile interface for controlling a PiRowFlo[m
[32m+[m[32minstallation, monitoring SmartRow live data and running structured rowing[m
[32m+[m[32mworkouts loaded from a Nextcloud calendar.[m
[32m+[m
[32m+[m[32mThe app communicates with the[m
 [PiRowFlo Control API](https://github.com/stampede79/pirowflo-control-api).[m
 [m
 <p align="center">[m
[36m@@ -14,6 +17,8 @@[m [mmonitoring a PiRowFlo installation. It communicates with the[m
 [m
 ## Features[m
 [m
[32m+[m[32m### PiRowFlo control[m
[32m+[m
 - Display the current PiRowFlo status[m
 - Display the SmartRow connection status[m
 - Start PiRowFlo in different modes:[m
[36m@@ -22,41 +27,199 @@[m [mmonitoring a PiRowFlo installation. It communicates with the[m
   - ANT+ only[m
 - Restart PiRowFlo[m
 - Stop PiRowFlo[m
[31m-- Reset the current training session[m
[32m+[m[32m- Reset the current SmartRow training session[m
 - Configure the PiRowFlo server and API key[m
[32m+[m[32m- Configure the app using a QR code[m
[32m+[m
[32m+[m[32m### SmartRow live metrics[m
[32m+[m
[32m+[m[32mDuring a workout the app displays live SmartRow data provided by PiRowFlo:[m
[32m+[m
[32m+[m[32m- Power in watts[m
[32m+[m[32m- Stroke rate (SPM)[m
[32m+[m[32m- Pace per 500 m[m
[32m+[m[32m- Distance[m
[32m+[m[32m- SmartRow connection state[m
[32m+[m
[32m+[m[32mThe workout screen polls the PiRowFlo Control API for live metrics while[m
[32m+[m[32mPiRowFlo continues to handle the SmartRow connection and its Bluetooth / ANT+[m
[32m+[m[32moutputs.[m
[32m+[m
[32m+[m[32mThis allows SmartRow data to be used by the app without requiring a second[m
[32m+[m[32mdirect Bluetooth connection to SmartRow.[m
[32m+[m
[32m+[m[32m### Power target guidance[m
[32m+[m
[32m+[m[32mWorkout steps can define a target power range.[m
[32m+[m
[32m+[m[32mThe current power value is color-coded:[m
[32m+[m
[32m+[m[32m- Green: inside the target range[m
[32m+[m[32m- Orange: up to 5% outside the target range[m
[32m+[m[32m- Red: more than 5% outside the target range[m
[32m+[m
[32m+[m[32mThe displayed watt value always represents the current SmartRow measurement.[m
[32m+[m
[32m+[m[32m### Nextcloud training calendar[m
[32m+[m
[32m+[m[32mPiRowFlo Control can load the planned workout for the current day from a[m
[32m+[m[32mNextcloud calendar using CalDAV.[m
[32m+[m
[32m+[m[32mThe following settings are stored securely on the Android device:[m
[32m+[m
[32m+[m[32m- CalDAV calendar URL[m
[32m+[m[32m- Nextcloud username[m
[32m+[m[32m- Nextcloud app password[m
[32m+[m
[32m+[m[32mA calendar connection test is available from the app settings.[m
[32m+[m
[32m+[m[32mNormal calendar descriptions can be combined with a machine-readable[m
[32m+[m[32m`[PIROWFLO]` block.[m
[32m+[m
[32m+[m[32mExample:[m
[32m+[m
[32m+[m[32m```text[m
[32m+[m[32m[PIROWFLO][m
[32m+[m[32mwarmup=7m[m
[32m+[m[32mrepeat=5[m
[32m+[m[32mwork=3m,135-145w[m
[32m+[m[32mrecovery=2m,90-100w[m
[32m+[m[32mcooldown=5m[m
[32m+[m[32m[/PIROWFLO][m
[32m+[m[32m```[m
[32m+[m
[32m+[m[32mThis produces:[m
[32m+[m
[32m+[m[32m```text[m
[32m+[m[32m7 min warm-up[m
[32m+[m
[32m+[m[32m5 x:[m
[32m+[m[32m  3 min at 135-145 W[m
[32m+[m[32m  2 min at 90-100 W[m
[32m+[m
[32m+[m[32m5 min cool-down[m
[32m+[m[32m```[m
[32m+[m
[32m+[m[32mStroke-rate targets are also supported:[m
[32m+[m
[32m+[m[32m```text[m
[32m+[m[32m[PIROWFLO][m
[32m+[m[32mwarmup=5m[m
[32m+[m[32mwork=40m,105-110w,16-18spm[m
[32m+[m[32mcooldown=5m[m
[32m+[m[32m[/PIROWFLO][m
[32m+[m[32m```[m
[32m+[m
[32m+[m[32mCalendar events without a `[PIROWFLO]` block are not treated as runnable[m
[32m+[m[32mworkouts.[m
[32m+[m
[32m+[m[32m### Guided workout runner[m
[32m+[m
[32m+[m[32mStructured workouts are executed step by step in the app.[m
[32m+[m
[32m+[m[32mThe workout screen provides:[m
[32m+[m
[32m+[m[32m- Current workout step[m
[32m+[m[32m- Remaining step time[m
[32m+[m[32m- Progress indicator[m
[32m+[m[32m- Current power[m
[32m+[m[32m- Target power[m
[32m+[m[32m- Stroke rate[m
[32m+[m[32m- Pace[m
[32m+[m[32m- Distance[m
[32m+[m[32m- SmartRow live/offline status[m
[32m+[m[32m- Pause and resume[m
[32m+[m[32m- Manual step skipping[m
[32m+[m
[32m+[m[32mThe Android display is kept awake while the workout screen is open.[m
[32m+[m
[32m+[m[32m### Audio cues[m
[32m+[m
[32m+[m[32mThe workout runner provides audio feedback so the display does not need to be[m
[32m+[m[32mwatched continuously.[m
[32m+[m
[32m+[m[32m- Countdown signals at 3, 2 and 1 seconds[m
[32m+[m[32m- Separate signal when a work interval begins[m
[32m+[m[32m- Separate signal when a recovery or cool-down begins[m
[32m+[m[32m- Completion signal when the workout finishes[m
[32m+[m
[32m+[m[32m### Workout recording[m
[32m+[m
[32m+[m[32mSmartRow metrics are recorded for each workout step while the workout is[m
[32m+[m[32mrunning.[m
[32m+[m
[32m+[m[32mThe result of each step includes:[m
[32m+[m
[32m+[m[32m- Actual duration[m
[32m+[m[32m- Average power[m
[32m+[m[32m- Average stroke rate[m
[32m+[m[32m- Average pace[m
[32m+[m[32m- Distance[m
[32m+[m[32m- Percentage of active power samples inside the target range[m
[32m+[m
[32m+[m[32mZero-power / idle samples are excluded from power target evaluation.[m
[32m+[m
[32m+[m[32mAfter the final step, the app displays a workout result screen containing the[m
[32m+[m[32mindividual step results and an overall workout summary.[m
[32m+[m
[32m+[m[32mThe overall summary includes:[m
[32m+[m
[32m+[m[32m- Total training time[m
[32m+[m[32m- Total distance[m
[32m+[m[32m- Average power[m
[32m+[m[32m- Average stroke rate[m
[32m+[m[32m- Average pace[m
[32m+[m[32m- Overall percentage inside configured power target ranges[m
[32m+[m
[32m+[m[32mWorkout results are currently kept in memory only and are not yet persisted.[m
 [m
 ## Architecture[m
 [m
 ```text[m
[31m-PiRowFlo Control App[m
[31m-        |[m
[31m-        | HTTP / REST[m
[31m-        v[m
[31m-PiRowFlo Control API[m
[31m-        |[m
[31m-        | Supervisor / control socket[m
[31m-        v[m
[31m-PiRowFlo[m
[31m-        |[m
[31m-        +---- SmartRow[m
[31m-        |[m
[31m-        +---- Bluetooth / FTMS[m
[31m-        |[m
[31m-        +---- ANT+[m
[31m-```[m
[31m-[m
[31m-The three components are maintained in separate repositories:[m
[31m-[m
[31m-- PiRowFlo  [m
[31m-  https://github.com/stampede79/pirowflo[m
[31m-- PiRowFlo Control API  [m
[31m-  https://github.com/stampede79/pirowflo-control-api[m
[31m-- PiRowFlo Control App  [m
[31m-  https://github.com/stampede79/pirowflo-control-app[m
[32m+[m[32m                         Nextcloud[m
[32m+[m[32m                            |[m
[32m+[m[32m                            | CalDAV[m
[32m+[m[32m                            v[m
[32m+[m[32m                    PiRowFlo Control App[m
[32m+[m[32m                            |[m
[32m+[m[32m                            | HTTP / REST[m
[32m+[m[32m                            v[m
[32m+[m[32m                    PiRowFlo Control API[m
[32m+[m[32m                            |[m
[32m+[m[32m                  +---------+---------+[m
[32m+[m[32m                  |                   |[m
[32m+[m[32m          Supervisor control      Unix socket[m
[32m+[m[32m                                      |[m
[32m+[m[32m                                      v[m
[32m+[m[32m                                  PiRowFlo[m
[32m+[m[32m                                      |[m
[32m+[m[32m                    +-----------------+-----------------+[m
[32m+[m[32m                    |                 |                 |[m
[32m+[m[32m                 SmartRow        Bluetooth / FTMS      ANT+[m
[32m+[m[32m                    |[m
[32m+[m[32m                    v[m
[32m+[m[32m              Live metrics[m
[32m+[m[32m                    |[m
[32m+[m[32m                    +----> Control API ----> App[m
[32m+[m[32m```[m
[32m+[m
[32m+[m[32mSmartRow remains connected to PiRowFlo. The Android app does not connect[m
[32m+[m[32mdirectly to SmartRow.[m
[32m+[m
[32m+[m[32mThis keeps the existing PiRowFlo Bluetooth / FTMS and ANT+ data paths[m
[32m+[m[32mindependent from the workout UI.[m
[32m+[m
[32m+[m[32m## Components[m
[32m+[m
[32m+[m[32mThe components are maintained in separate repositories:[m
[32m+[m
[32m+[m[32m- [PiRowFlo](https://github.com/stampede79/pirowflo)[m
[32m+[m[32m- [PiRowFlo Control API](https://github.com/stampede79/pirowflo-control-api)[m
[32m+[m[32m- [PiRowFlo Control App](https://github.com/stampede79/pirowflo-control-app)[m
 [m
 For a complete Raspberry Pi installation, see:[m
 [m
[31m-https://github.com/stampede79/pirowflo-installer[m
[32m+[m[32m- [PiRowFlo Installer](https://github.com/stampede79/pirowflo-installer)[m
 [m
 ## Requirements[m
 [m
[36m@@ -69,7 +232,7 @@[m [mTo build the app you need:[m
 - Git[m
 - an Android device or emulator[m
 [m
[31m-Check your Flutter environment with:[m
[32m+[m[32mCheck the Flutter environment with:[m
 [m
 ```bash[m
 flutter doctor[m
[36m@@ -82,76 +245,70 @@[m [mResolve any reported Android toolchain issues before building the app.[m
 ```bash[m
 git clone https://github.com/stampede79/pirowflo-control-app.git[m
 cd pirowflo-control-app[m
[31m-```[m
[31m-[m
[31m-Install the Flutter dependencies:[m
[31m-[m
[31m-```bash[m
 flutter pub get[m
 ```[m
 [m
[31m-## Run in development mode[m
[32m+[m[32m## Development[m
 [m
[31m-Connect an Android device with USB debugging enabled or start an Android[m
[31m-emulator.[m
[31m-[m
[31m-Check that Flutter can see the device:[m
[32m+[m[32mCheck the project with:[m
 [m
 ```bash[m
[31m-flutter devices[m
[32m+[m[32mflutter analyze[m
[32m+[m[32mflutter test[m
 ```[m
 [m
[31m-Then start the app:[m
[32m+[m[32mRun it on a connected development device:[m
 [m
 ```bash[m
[32m+[m[32mflutter devices[m
 flutter run[m
 ```[m
 [m
 ## Build an Android APK[m
 [m
[31m-Create a release APK with:[m
[32m+[m[32m### Debug APK[m
 [m
 ```bash[m
[31m-flutter build apk --release[m
[32m+[m[32mflutter build apk --debug[m
 ```[m
 [m
[31m-The resulting APK can be found at:[m
[32m+[m[32mResult:[m
 [m
 ```text[m
[31m-build/app/outputs/flutter-apk/app-release.apk[m
[32m+[m[32mbuild/app/outputs/flutter-apk/app-debug.apk[m
 ```[m
 [m
[31m-## Install the APK[m
[31m-[m
[31m-### Using ADB[m
[31m-[m
[31m-With an Android device connected:[m
[32m+[m[32m### Release APK[m
 [m
 ```bash[m
[31m-adb install -r build/app/outputs/flutter-apk/app-release.apk[m
[32m+[m[32mflutter build apk --release[m
 ```[m
 [m
[31m-### Manual installation[m
[31m-[m
[31m-Alternatively, copy[m
[32m+[m[32mResult:[m
 [m
 ```text[m
 build/app/outputs/flutter-apk/app-release.apk[m
 ```[m
 [m
[31m-to the Android device and open the APK there.[m
[32m+[m[32m## Install using ADB[m
[32m+[m
[32m+[m[32mFor a connected Android device:[m
[32m+[m
[32m+[m[32m```bash[m
[32m+[m[32madb install -r build/app/outputs/flutter-apk/app-debug.apk[m
[32m+[m[32m```[m
 [m
[31m-Android may ask for permission to install apps from the application used to[m
[31m-open the APK.[m
[32m+[m[32mThe APK can alternatively be copied to the Android device and installed[m
[32m+[m[32mmanually.[m
 [m
 ## App configuration[m
 [m
 Open the settings using the gear icon in the upper-right corner.[m
 [m
[31m-### Server[m
[32m+[m[32m### PiRowFlo server[m
 [m
[31m-Enter the complete base URL of the PiRowFlo Control API including the protocol[m
[31m-and port.[m
[32m+[m[32mEnter the complete base URL of the PiRowFlo Control API including protocol and[m
[32m+[m[32mport.[m
 [m
 Example:[m
 [m
[36m@@ -159,40 +316,69 @@[m [mExample:[m
 http://192.168.178.123:8090[m
 ```[m
 [m
[31m-Do not append `/api/status` or another API path. The app adds the required API[m
[31m-paths automatically.[m
[32m+[m[32mDo not append `/api/status`, `/api/metrics` or another API path.[m
 [m
 ### API key[m
 [m
[31m-Enter the API key generated during installation of the PiRowFlo Control API.[m
[32m+[m[32mThe Control API uses an API key sent by the app using the `X-API-Key` HTTP[m
[32m+[m[32mheader.[m
 [m
[31m-On the PiRowFlo host, the configured key can be displayed with:[m
[31m-[m
[31m-```bash[m
[31m-sudo grep '^PIROWFLO_API_KEY=' /etc/pirowflo-control.env[m
[31m-```[m
[31m-[m
[31m-The app sends the key using the `X-API-Key` HTTP header.[m
[32m+[m[32mThe key is configured on the PiRowFlo host through the Control API environment[m
[32m+[m[32mconfiguration.[m
 [m
 The server address and API key are stored locally using Flutter Secure Storage.[m
 [m
 Keep the API key private.[m
 [m
[31m-## PiRowFlo modes[m
[32m+[m[32m### Nextcloud calendar[m
 [m
[31m-### Bluetooth + ANT+[m
[32m+[m[32mConfigure:[m
 [m
[31m-Starts PiRowFlo with both FTMS Bluetooth broadcasting and ANT+ enabled.[m
[32m+[m[32m- CalDAV calendar URL[m
[32m+[m[32m- Nextcloud username[m
[32m+[m[32m- Nextcloud app password[m
 [m
[31m-This is the normal combined mode.[m
[32m+[m[32mExample calendar URL:[m
[32m+[m
[32m+[m[32m```text[m
[32m+[m[32mhttps://cloud.example.com/remote.php/dav/calendars/USER/training/[m
[32m+[m[32m```[m
 [m
[31m-### Bluetooth[m
[32m+[m[32mUse a dedicated Nextcloud app password instead of the normal account password.[m
 [m
[31m-Starts PiRowFlo with FTMS Bluetooth broadcasting only.[m
[32m+[m[32mThe app provides a calendar test function before using the configuration for[m
[32m+[m[32mworkouts.[m
 [m
[31m-### ANT+[m
[32m+[m[32m## PiRowFlo Control API[m
 [m
[31m-Starts PiRowFlo with ANT+ broadcasting only.[m
[32m+[m[32mThe app currently uses endpoints including:[m
[32m+[m
[32m+[m[32m```text[m
[32m+[m[32mGET  /api/status[m
[32m+[m[32mGET  /api/metrics[m
[32m+[m
[32m+[m[32mPOST /api/start/combined[m
[32m+[m[32mPOST /api/start/bluetooth[m
[32m+[m[32mPOST /api/start/ant[m
[32m+[m[32mPOST /api/restart[m
[32m+[m[32mPOST /api/reset[m
[32m+[m[32mPOST /api/stop[m
[32m+[m[32m```[m
[32m+[m
[32m+[m[32m`/api/metrics` exposes normalized SmartRow live data such as:[m
[32m+[m
[32m+[m[32m```json[m
[32m+[m[32m{[m
[32m+[m[32m  "smartrow_connected": true,[m
[32m+[m[32m  "smartrow_ready": true,[m
[32m+[m[32m  "rowing": true,[m
[32m+[m[32m  "power_w": 139,[m
[32m+[m[32m  "stroke_rate_spm": 24,[m
[32m+[m[32m  "pace_500m_seconds": 139,[m
[32m+[m[32m  "distance_m": 1240,[m
[32m+[m[32m  "elapsed_seconds": 420[m
[32m+[m[32m}[m
[32m+[m[32m```[m
 [m
 ## Troubleshooting[m
 [m
[36m@@ -206,17 +392,12 @@[m [msystemctl status pirowflo-control.service[m
 [m
 Check that port `8090` is reachable from the Android device.[m
 [m
[31m-### Authentication fails[m
[32m+[m[32m### SmartRow is offline[m
 [m
[31m-Verify that the API key configured in the app matches:[m
[32m+[m[32mThe app distinguishes between the Control API being reachable and SmartRow[m
[32m+[m[32mbeing connected.[m
 [m
[31m-```bash[m
[31m-sudo grep '^PIROWFLO_API_KEY=' /etc/pirowflo-control.env[m
[31m-```[m
[31m-[m
[31m-### PiRowFlo does not start[m
[31m-[m
[31m-Check the Supervisor status:[m
[32m+[m[32mCheck PiRowFlo:[m
 [m
 ```bash[m
 /opt/pirowflo/venv/bin/supervisorctl \[m
[36m@@ -230,6 +411,35 @@[m [mCheck the PiRowFlo log:[m
 tail -n 100 /opt/pirowflo/src/pirowflo.log[m
 ```[m
 [m
[32m+[m[32m### Nextcloud calendar cannot be accessed[m
[32m+[m
[32m+[m[32mVerify the CalDAV URL and use a valid Nextcloud app password.[m
[32m+[m
[32m+[m[32mA working CalDAV calendar should respond successfully to an authenticated[m
[32m+[m[32m`PROPFIND` request.[m
[32m+[m
[32m+[m[32m### No live workout values[m
[32m+[m
[32m+[m[32mVerify:[m
[32m+[m
[32m+[m[32m1. PiRowFlo is running.[m
[32m+[m[32m2. SmartRow is connected.[m
[32m+[m[32m3. SmartRow services are resolved.[m
[32m+[m[32m4. `/api/metrics` is reachable.[m
[32m+[m[32m5. The API key is correct.[m
[32m+[m
[32m+[m[32m## Current limitations / planned work[m
[32m+[m
[32m+[m[32mThe following features are not implemented yet:[m
[32m+[m
[32m+[m[32m- Persistent workout history[m
[32m+[m[32m- Saving completed workout results[m
[32m+[m[32m- Synchronizing workout results back to Nextcloud[m
[32m+[m[32m- Historical workout analysis and trends[m
[32m+[m[32m- Additional workout result visualizations[m
[32m+[m[32m- Optional smoothing of live power target feedback[m
[32m+[m[32m- Garmin Connect IQ integration[m
[32m+[m
 ## Related projects[m
 [m
 - [PiRowFlo](https://github.com/stampede79/pirowflo)[m
