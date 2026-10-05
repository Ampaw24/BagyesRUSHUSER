#!/bin/sh
# Xcode build phase: copies MAPS_IOS_KEY from Flutter's DART_DEFINES
# (--dart-define-from-file=env/app.json) into the *built* Info.plist as
# GMSApiKey. The key never lands in a source file or a bundled asset.

key=""
OLD_IFS="$IFS"; IFS=','
for define in $DART_DEFINES; do
  decoded=$(printf '%s' "$define" | base64 --decode 2>/dev/null)
  case "$decoded" in MAPS_IOS_KEY=*) key="${decoded#MAPS_IOS_KEY=}" ;; esac
done
IFS="$OLD_IFS"

if [ -z "$key" ]; then
  if [ "$CONFIGURATION" = "Debug" ]; then
    echo "warning: MAPS_IOS_KEY missing — build with --dart-define-from-file=env/app.json (Google Maps will not render)."
    exit 0
  fi
  echo "error: MAPS_IOS_KEY missing — build with --dart-define-from-file=env/app.json."
  exit 1
fi

/usr/libexec/PlistBuddy -c "Set :GMSApiKey $key" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
