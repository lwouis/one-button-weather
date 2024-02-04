#!/usr/bin/env bash

set -exu

xcodeBuildPath="DerivedData/Build/Products/Release"
version="$(awk -F ' = ' '/^VERSION/ { print $2; }' < config/base.xcconfig)"
appName="$(awk -F ' = ' '/^PRODUCT_NAME/ { print $2; }' < config/base.xcconfig)"
appFile="$appName.app"
zipName="$appName-$version.zip"
oldPwd="$PWD"

cd "$xcodeBuildPath"
ditto -c -k --keepParent "$appFile" "$zipName"

# request notarization
requestStatus=$("$oldPwd"/scripts/notarytool submit \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  "$zipName" \
  --wait --timeout 15m 2>&1 |
  tee /dev/tty |
  awk -F ': ' '/  status:/ { print $2; }')
if [[ $requestStatus != "Accepted" ]]; then exit 1; fi

# staple build
xcrun stapler staple "$appFile"
ditto -c -k --keepParent "$appFile" "$zipName"
