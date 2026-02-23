#!/usr/bin/env bash
set -euo pipefail

PROJECT="OpenGpxTracker.xcodeproj"
TARGET="OpenGpxTracker"
CONFIGURATION="Release"
BUILD_DIR="build"
PRODUCT_DIR="${BUILD_DIR}/Products"
APP_PATH="${PRODUCT_DIR}/OpenGpxTracker.app"
PAYLOAD_DIR="${BUILD_DIR}/Payload"
IPA_PATH="${BUILD_DIR}/OpenGpxTracker_unsigned.ipa"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

xcodebuild \
  -project "${PROJECT}" \
  -target "${TARGET}" \
  -configuration "${CONFIGURATION}" \
  -sdk iphoneos \
  CONFIGURATION_BUILD_DIR="${PRODUCT_DIR}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  clean build

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
