#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
: "${DAYWELL_KEYSTORE:?Set the absolute path to the signing keystore}"
: "${DAYWELL_STORE_PASSWORD:?Set the keystore password}"
flutter_root="${FLUTTER_ROOT:-$(cd "$(dirname "$(realpath "$(command -v flutter)")")/.." && pwd)}"
printf 'flutter.sdk=%s\nsdk.dir=%s\n' "$flutter_root" "${ANDROID_HOME:?Set ANDROID_HOME}" > android/local.properties
flutter pub get
(cd android && gradle wrapper --gradle-distribution-url https://downloads.gradle.org/distributions/gradle-8.10.2-bin.zip)
flutter test
for device in phone watch; do
  flutter build apk --release --flavor "$device"
  flutter build appbundle --release --flavor "$device"
done
