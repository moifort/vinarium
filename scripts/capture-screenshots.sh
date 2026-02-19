#!/bin/bash
set -euo pipefail

# Screenshot capture script for Cave-a-Vin mockup generation
# Requires: Xcode, iOS Simulator, backend running

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ -z "${NITRO_API_TOKEN:-}" ]; then
  echo "Error: NITRO_API_TOKEN is not set. Export it before running this script." >&2
  exit 1
fi
API_TOKEN="$NITRO_API_TOKEN"
OUTPUT_DIR="$PROJ_DIR/generated/screenshots"
SCHEME="CaveAVin"
DEVICE="iPhone 17"
OS="26.2"
DESTINATION="platform=iOS Simulator,name=$DEVICE,OS=$OS"

mkdir -p "$OUTPUT_DIR"

screenshot() {
  local name="$1"
  local filename="$OUTPUT_DIR/$name.png"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📸 Screenshot: $name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Navigate to the correct screen, then press ENTER..."
  read -r
  xcrun simctl io booted screenshot "$filename"
  echo "  ✓ Saved: $filename"
}

echo "╔══════════════════════════════════════════╗"
echo "║   Cave-a-Vin Screenshot Capture Tool     ║"
echo "╠══════════════════════════════════════════╣"
echo "║ Output: generated/screenshots/            ║"
echo "║ Screens: 13 total                         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Step 1: Build and install
echo "Step 1: Building and installing app..."
echo "  Building $SCHEME for $DEVICE..."
xcodebuild \
  -project "$PROJ_DIR/ios/CaveAVin.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  build \
  2>&1 | tail -1

# Boot simulator if needed
echo "  Booting simulator..."
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator

echo ""
echo "  ✓ App built and simulator ready"
echo ""

# Step 2: Seed test data
echo "Step 2: Seeding test data..."
echo "  Make sure the backend is running (bun run dev)"
echo "  Press ENTER to seed data..."
read -r
cd "$PROJ_DIR" && bun run scripts/seed-test-data.ts
echo ""

# Step 3: Install and launch app
echo "Step 3: Installing app..."
APP_PATH=$(find "$PROJ_DIR/.derivedData" "$HOME/Library/Developer/Xcode/DerivedData" \
  -name "CaveAVin.app" -path "*/Debug-iphonesimulator/*" 2>/dev/null | head -1)
if [ -n "$APP_PATH" ]; then
  xcrun simctl install booted "$APP_PATH"
  xcrun simctl launch booted com.music-notation.CaveAVin 2>/dev/null || \
    xcrun simctl launch booted "$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier 2>/dev/null || echo 'CaveAVin')" 2>/dev/null || true
  echo "  ✓ App installed and launched"
else
  echo "  ⚠ Could not find built app. Please launch it manually from Xcode."
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  PHASE 1: Screens with data"
echo "═══════════════════════════════════════════"

screenshot "01-dashboard"
screenshot "02-cellar-grid"
screenshot "03-cellar-journal"
screenshot "04-wine-list"
screenshot "05-wine-detail"
screenshot "06-consumption-sheet"

echo ""
echo "═══════════════════════════════════════════"
echo "  PHASE 2: Scan flow"
echo "═══════════════════════════════════════════"
echo ""
echo "Start the scan flow from the + tab."
echo "You'll capture each step of the process."
echo ""

screenshot "07-scan-camera"
screenshot "08-scan-analyzing"
screenshot "09-scan-review"
screenshot "10-scan-placement"
screenshot "11-scan-confirmation"

echo ""
echo "═══════════════════════════════════════════"
echo "  PHASE 3: Empty states"
echo "═══════════════════════════════════════════"
echo ""
echo "Resetting database for empty state screenshots..."
echo "Press ENTER to reset and restart app..."
read -r
cd "$PROJ_DIR" && curl -s -X POST -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:3000/test/reset > /dev/null
echo "  ✓ Database reset. Pull to refresh in the app."
echo ""

screenshot "12-empty-cellar"
screenshot "13-empty-wine-list"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   ✓ All 13 screenshots captured!          ║"
echo "╠══════════════════════════════════════════╣"
echo "║   Check: generated/screenshots/            ║"
echo "╚══════════════════════════════════════════╝"
ls -la "$OUTPUT_DIR"
