#!/bin/bash
# Rebuild the OpenSSL xcframework for BridgeArchiver-Swift.
# Requires Xcode (for the iOS SDK, xcrun, and xcodebuild -create-xcframework).
# Run from anywhere: ./openssl/rebuild-openssl.sh

set -e

OPENSSL_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="3.5.7"
TEMP_DIR="${OPENSSL_DIR}/.buildtmp"
XCFRAMEWORK="${OPENSSL_DIR}/build/openssl.xcframework"

build_platform() {
    local PLATFORM=$1   # iphoneos | iphonesimulator
    local ARCHS=$2      # "arm64" | "arm64 x86_64"
    local OUT="${TEMP_DIR}/${PLATFORM}"
    local DERIVED="${TEMP_DIR}/derived-${PLATFORM}"
    mkdir -p "${OUT}" "${DERIVED}"

    echo "Building for ${PLATFORM} (${ARCHS})..."
    (cd "${OPENSSL_DIR}" && \
    COMMAND_MODE=unix2003 \
    VERSION="${VERSION}" \
    PLATFORM_NAME="${PLATFORM}" \
    ARCHS_STANDARD="${ARCHS}" \
    BUILT_PRODUCTS_DIR="${OUT}" \
    PRODUCT_NAME="openssl" \
    DERIVED_FILE_DIR="${DERIVED}" \
    ./build-libssl.sh)

    libtool -static \
        "${OUT}/openssl/libssl.a" \
        "${OUT}/openssl/libcrypto.a" \
        -o "${OUT}/openssl/libopenssl.a"
}

echo "Building OpenSSL ${VERSION}..."
rm -rf "${TEMP_DIR}" "${XCFRAMEWORK}"
mkdir -p "${TEMP_DIR}" "${OPENSSL_DIR}/build"

build_platform "iphoneos"        "arm64"
build_platform "iphonesimulator" "arm64 x86_64"

echo "Packaging xcframework..."
xcodebuild -create-xcframework \
    -library "${TEMP_DIR}/iphoneos/openssl/libopenssl.a" \
    -headers "${TEMP_DIR}/iphoneos/openssl/include" \
    -library "${TEMP_DIR}/iphonesimulator/openssl/libopenssl.a" \
    -headers "${TEMP_DIR}/iphonesimulator/openssl/include" \
    -output "${XCFRAMEWORK}"

rm -rf "${TEMP_DIR}"
echo "Done: ${XCFRAMEWORK}"
