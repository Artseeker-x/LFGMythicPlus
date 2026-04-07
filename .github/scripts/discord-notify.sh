#!/usr/bin/env bash
set -euo pipefail

# Version: prefer explicit override (manual trigger), fall back to git tag
if [ -n "${NOTIFY_VERSION:-}" ]; then
    VERSION="$NOTIFY_VERSION"
    # Read RELEASE_NOTES.md from the specific version tag so notes are always accurate
    git show "v${VERSION}:RELEASE_NOTES.md" > /tmp/release_notes.md 2>/dev/null \
        && NOTES_FILE="/tmp/release_notes.md" \
        || NOTES_FILE="RELEASE_NOTES.md"
else
    VERSION="${GITHUB_REF_NAME#v}"
    NOTES_FILE="RELEASE_NOTES.md"
fi

# Detect release type from section headers
TYPE=""
grep -q "^### Added"   "$NOTES_FILE" && TYPE="${TYPE:+$TYPE / }feature"
grep -q "^### Fixed"   "$NOTES_FILE" && TYPE="${TYPE:+$TYPE / }fix"
grep -q "^### Changed" "$NOTES_FILE" && TYPE="${TYPE:+$TYPE / }update"
grep -q "^### Removed" "$NOTES_FILE" && TYPE="${TYPE:+$TYPE / }cleanup"
[ -z "$TYPE" ] && TYPE="update"

# Get the CurseForge file ID for this specific version
CF_FILE_ID=$(curl -s \
  -H "x-api-key: ${CF_API_KEY}" \
  "https://api.curseforge.com/v1/mods/1495435/files?pageSize=10&sortOrder=desc" \
  | jq -r --arg ver "$VERSION" '[.data[] | select(.displayName | test($ver))] | .[0].id')
CF_URL="https://www.curseforge.com/wow/addons/lfg-mythic/files/${CF_FILE_ID}"
GH_URL="https://github.com/Artseeker-x/LFGMythicPlus/releases/tag/v${VERSION}"

# Format notes: bullets, auto-bold key terms
NOTES=$(grep "^- " "$NOTES_FILE" \
  | sed \
      -e 's/^- /• /' \
      -e 's/Raider\.IO/**Raider.IO**/g' \
      -e 's/LFG Mythic+/**LFG Mythic+**/g' \
      -e 's/Blizzard/**Blizzard**/g' \
      -e 's/PVEFrame/**PVEFrame**/g')

# Gold #FFD100 = 16760576
jq -n \
  --arg  version "$VERSION" \
  --arg  type    "$TYPE" \
  --arg  notes   "$NOTES" \
  --arg  cf_url  "$CF_URL" \
  --arg  gh_url  "$GH_URL" \
  --argjson color 16760576 \
  '{
    username: "LFG Mythic+",
    embeds: [{
      author: { name: "🔑  New Update Available" },
      title:  ("v" + $version + " — Now Live"),
      url:    $cf_url,
      color:  $color,
      description: $notes,
      fields: [
        { name: "Version",  value: $version, inline: true },
        { name: "Type",     value: $type,    inline: true },
        {
          name:   "Download",
          value:  ("**[📦 CurseForge](" + $cf_url + ")**  •  [📎 GitHub Release](" + $gh_url + ")"),
          inline: false
        }
      ],
      footer:    { text: "World of Warcraft · Mythic+" },
      timestamp: (now | todate)
    }]
  }' \
| curl -s -X POST "$DISCORD_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d @-
