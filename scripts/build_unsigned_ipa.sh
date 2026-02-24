#!/usr/bin/env bash
set -euo pipefail

PROJECT="OpenGpxTracker.xcodeproj"
TARGET="OpenGpxTracker"
CONFIGURATION="Release"
BUILD_DIR="build"
PAYLOAD_DIR="${BUILD_DIR}/Payload"
IPA_PATH="${BUILD_DIR}/OpenGpxTracker_unsigned.ipa"
APP_NAME="OpenGpxTracker.app"
DERIVED_DATA_ROOT="${HOME}/Library/Developer/Xcode/DerivedData"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

xcodebuild \
  -project "${PROJECT}" \
  -target "${TARGET}" \
  -configuration "${CONFIGURATION}" \
  -destination 'generic/platform=iOS' \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="$(ls -td "${DERIVED_DATA_ROOT}"/*/Build/Products/${CONFIGURATION}-iphoneos/"${APP_NAME}" 2>/dev/null | head -n 1 || true)"
if [ ! -d "${APP_PATH}" ]; then
  echo "Expected app not found under ${DERIVED_DATA_ROOT}/*/Build/Products/${CONFIGURATION}-iphoneos/${APP_NAME}"
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
