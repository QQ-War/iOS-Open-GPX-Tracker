#!/usr/bin/env bash
set -euo pipefail

PROJECT="OpenGpxTracker.xcodeproj"
SCHEME="OpenGpxTracker"
CONFIGURATION="Release"
BUILD_DIR="build"
PAYLOAD_DIR="${BUILD_DIR}/Payload"
IPA_PATH="${BUILD_DIR}/OpenGpxTracker_unsigned.ipa"
APP_NAME="OpenGpxTracker.app"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .ci-derived-data \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH=".ci-derived-data/Build/Products/${CONFIGURATION}-iphoneos/${APP_NAME}"
if [ ! -d "${APP_PATH}" ]; then
  echo "Expected app not found at ${APP_PATH}"
  exit 1
fi

mkdir -p "${PAYLOAD_DIR}"
cp -R "${APP_PATH}" "${PAYLOAD_DIR}/"

(
  cd "${BUILD_DIR}"
  /usr/bin/zip -qry "$(basename "${IPA_PATH}")" Payload
)

if [ ! -f "${IPA_PATH}" ]; then
  echo "Unsigned IPA not generated"
  exit 1
fi

echo "Generated: ${IPA_PATH}"
