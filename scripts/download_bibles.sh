#!/bin/bash
# Download and convert Bible translations for Pau app.
# Usage: ./scripts/download_bibles.sh
# Saves to assets/bibles/<code>/verses.txt and metadata.json

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIBLES_DIR="$SCRIPT_DIR/assets/bibles"

echo "=== Downloading Burmese Judson Bible ==="
mkdir -p "$BIBLES_DIR/my_judson"
curl -sL "https://media.githubusercontent.com/media/thiagobodruk/bible/master/json/my_judson.json" -o /tmp/bur_temp.json 2>/dev/null

if [ -s /tmp/bur_temp.json ] && head -c 10 /tmp/bur_temp.json | grep -q "{"; then
  python3 -c "
import json
data = json.load(open('/tmp/bur_temp.json', encoding='utf-8-sig'))
verses = []
for book in data:
    for ch in book['chapters']:
        for v in ch:
            verses.append(v.strip())
with open('$BIBLES_DIR/my_judson/verses.txt', 'w') as f:
    f.write('\n'.join(verses))
print(f'Downloaded: {len(verses)} verses')
"
else
  echo "⚠ Could not download Burmese Bible automatically."
  echo "   Download manually from:"
  echo "   https://github.com/thiagobodruk/bible/blob/master/json/my_judson.json"
  echo "   Save as: $BIBLES_DIR/my_judson/verses.txt (one verse per line)"
fi

echo ""
echo "=== Downloading Malay Alkitab ==="
mkdir -p "$BIBLES_DIR/ms_alkitab"
curl -sL "https://media.githubusercontent.com/media/thiagobodruk/bible/master/json/ms_alkitab.json" -o /tmp/ms_temp.json 2>/dev/null

if [ -s /tmp/ms_temp.json ] && head -c 10 /tmp/ms_temp.json | grep -q "{"; then
  python3 -c "
import json
data = json.load(open('/tmp/ms_temp.json', encoding='utf-8-sig'))
verses = []
for book in data:
    for ch in book['chapters']:
        for v in ch:
            verses.append(v.strip())
with open('$BIBLES_DIR/ms_alkitab/verses.txt', 'w') as f:
    f.write('\n'.join(verses))
print(f'Downloaded: {len(verses)} verses')
"
else
  echo "⚠ Could not download Malay Bible automatically."
  echo "   Download manually from:"
  echo "   https://github.com/thiagobodruk/bible/blob/master/json/ms_alkitab.json"
  echo "   Save as: $BIBLES_DIR/ms_alkitab/verses.txt (one verse per line)"
fi

echo ""
echo "Done. If downloads failed, open the URLs in a browser on a machine with more bandwidth."
