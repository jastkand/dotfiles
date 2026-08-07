#!/bin/sh
# Point ~/.claude/settings.json at the installed statusline, touching nothing else.
#
# Only the "statusLine" key is written, so machine-local preferences (model, theme,
# effortLevel, enabledPlugins, ...) survive. Idempotent: it assigns rather than appends.
#
# Usage: patch-settings.sh [settings.json path]

set -e

settings=${1:-$HOME/.claude/settings.json}
command='sh ~/.claude/statusline.sh'

if ! command -v jq >/dev/null 2>&1; then
  echo "patch-settings: jq not found — add this to $settings by hand:" >&2
  echo "  \"statusLine\": {\"type\": \"command\", \"command\": \"$command\"}" >&2
  exit 1
fi

mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || printf '{}\n' > "$settings"

if ! jq -e . "$settings" >/dev/null 2>&1; then
  echo "patch-settings: $settings is not valid JSON — refusing to overwrite it." >&2
  exit 1
fi

tmp="$settings.tmp.$$"
jq --arg cmd "$command" '.statusLine = {type: "command", command: $cmd}' "$settings" > "$tmp"
mv "$tmp" "$settings"
echo "patch-settings: statusLine -> $command"
