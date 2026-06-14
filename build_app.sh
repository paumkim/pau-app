#!/bin/bash
# Build Pau app with secrets passed via dart-define (never hardcoded).
#
# Usage:
#   ./build_app.sh                  # Build debug APK
#   ./build_app.sh release          # Build release APK (requires key.properties)
#   ./build_app.sh bundle           # Build app bundle for Play Store
#
# Set these env vars or they'll default to empty strings (features degrade gracefully):
#   HF_TOKEN=<your_huggingface_token>
#   SENTRY_DSN=<your_sentry_dsn>
#
# Example:
#   HF_TOKEN=hf_xxx SENTRY_DSN=https://xxx@sentry.io/xxx ./build_app.sh release

set -e

MODE="${1:-debug}"
DEFINES=""

if [ -n "$HF_TOKEN" ]; then
  DEFINES="$DEFINES --dart-define=HF_TOKEN=$HF_TOKEN"
  echo "✓ HF_TOKEN set"
else
  echo "⚠ HF_TOKEN not set — Hugging Face model will not work"
fi

if [ -n "$SENTRY_DSN" ]; then
  DEFINES="$DEFINES --dart-define=SENTRY_DSN=$SENTRY_DSN"
  echo "✓ SENTRY_DSN set"
else
  echo "⚠ SENTRY_DSN not set — crash reporting disabled"
fi

case "$MODE" in
  release)
    echo "Building release APK..."
    flutter build apk --release $DEFINES
    echo "✓ Release APK: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  bundle)
    echo "Building app bundle..."
    flutter build appbundle --release $DEFINES
    echo "✓ App bundle: build/app/outputs/bundle/release/app-release.aab"
    ;;
  *)
    echo "Building debug APK..."
    flutter build apk --debug $DEFINES
    echo "✓ Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
    ;;
esac
