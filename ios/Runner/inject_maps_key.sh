#!/bin/sh
# Xcode build phase: copies MAPS_IOS_KEY from Flutter's DART_DEFINES
# (--dart-define-from-file=env/app.json) into the *built* Info.plist as
# GMSApiKey. The key never lands in a source file or a bundled asset.
#
# Non-Debug builds must also target the production API origin below. Xcode
# archives reuse whatever DART_DEFINES the last Flutter command wrote to the
# gitignored Generated.xcconfig, so a stale API_BASE_URL would otherwise ship.

expected_api_origin="https://api.gopady.com"

key=""
api_base_url=""
OLD_IFS="$IFS"; IFS=','
for define in $DART_DEFINES; do
  decoded=$(printf '%s' "$define" | base64 --decode 2>/dev/null)
  case "$decoded" in
    MAPS_IOS_KEY=*) key="${decoded#MAPS_IOS_KEY=}" ;;
    API_BASE_URL=*) api_base_url="${decoded#API_BASE_URL=}" ;;
  esac
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

if [ "$CONFIGURATION" != "Debug" ]; then
  case "$api_base_url" in
    "$expected_api_origin"/*) ;;
    *)
      echo "error: API_BASE_URL is '$api_base_url' but ${CONFIGURATION} builds must target $expected_api_origin — build with --dart-define-from-file=env/app.json."
      exit 1
      ;;
  esac
fi

/usr/libexec/PlistBuddy -c "Set :GMSApiKey $key" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
