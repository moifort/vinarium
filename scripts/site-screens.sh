#!/usr/bin/env bash
#
# The landing page's pictures of the app, taken from the captures
# (scripts/screenshots.sh): whole screens for the iPhones, in French and in
# English, so that every picture of the app is the app itself.
#
#   scripts/site-screens.sh
#
# Run after a capture run; the files land in site/screens/.
set -euo pipefail

cd "$(dirname "$0")/.."

SCREENS="dashboard cellar wine-list scan-review wine-detail journal"

mkdir -p site/screens
for lang in fr en; do
  # French is what the README embeds, at the root of screenshots/.
  from="screenshots"
  [[ "$lang" != fr ]] && from="screenshots/$lang"
  for shot in $SCREENS; do
    sips -Z 1434 -s format jpeg -s formatOptions 60 "$from/$shot.png" \
      --out "site/screens/$lang-$shot.jpg" >/dev/null
  done
done

# The icon, for the page and the browser tab.
icon="ios/Vinarium/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
sips -Z 256 "$icon" --out site/icon-256.png >/dev/null
sips -Z 64 "$icon" --out site/favicon.png >/dev/null

ls site/screens
