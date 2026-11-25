# OnArc-Test---GPT
ChatGPT's OnArc

# Daywell
A standalone Flutter agenda with one daily dial. The Android flavors use Java for notifications, document access, Bluetooth and Wear OS surfaces.

## Build on a development machine
Use an installed Flutter 3.29.x SDK, JDK 17, Android SDK 35, and Gradle 8.10.2. From this directory on macOS or Linux run `bash build.sh`. The script runs Dart tests then creates release-mode APKs for both devices. Install with `adb -s DEVICE_SERIAL install -r PATH_TO_APK`. Supply the signing environment variables below before building. The project includes no downloaded dependencies. First build needs access to published SDK and artifact distributions.

## Signing
Use the private PKCS12 file and recovery password supplied separately. Set DAYWELL_KEYSTORE to its absolute path and DAYWELL_STORE_PASSWORD to the password via a secret manager or hidden shell prompt. Alias: daywell. Keep an independent encrypted offline copy. Keep signing material out of the source directory. A Play upload key and Google's app signing key have different roles.

## Daily use
Open the menu to switch between Today, Dial editor, Templates and Settings. One dial repeats every day. End times are exclusive. Editing and deleting the sample changes the actual saved dial. Restoring a file validates the whole replacement before saving. Empty space is open time. Backups contain only the plan. Settings are device-specific.

To copy the dial, open Receive from phone on the watch and select the paired phone. Within one minute choose Send to watch on the phone and select the watch. Each successful receive replaces the watch's local plan. Sync is manual. Focus opens a view of the current scheduled arc and expires when that arc leaves the display. The watch schedules its own notifications and can operate disconnected.

Local clock time follows travel. The dial shows the repeated wall-clock hour twice on a fall-back day and skips the spring-forward gap. Start notifications use the first occurrence in a repeated hour and omit nonexistent starts. Remaining minutes describe dial distance to the end. Minute 1440 is an exclusive end at midnight.

## Verification status
The source was assembled without a Flutter SDK, Android SDK, emulator, or paired devices. Only the Java scheduling checks and static packaging checks were run. Device screenshots, signed app builds, closed testing, daily use, and production release are outstanding. See release/ for store copy and device acceptance checks.
