#!/bin/sh
# Refresh the cached Claude usage report.
#
# Writes ~/.claude/usage-cache.json, consumed by two things:
#   - statusline.sh, which renders a compact segment from the parsed fields
#   - the /my-usage skill, which reads .report for the full text
#
# Shape:
#   {
#     "fetched_at":  <epoch>,
#     "session":     {"pct":73,"reset_text":"Aug 7 at 7pm (Asia/Omsk)","reset_epoch":<epoch|null>},
#     "weeks":       [{"label":"W","name":"all models","pct":64,"reset_text":...,"reset_epoch":...}, ...],
#     "max_pct":     78,
#     "report":      "<full /usage text>"
#   }
#
# Spawned in the background by statusline.sh, or run directly by the skill. A lock
# keeps concurrent sessions from all refreshing at once.

PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export PATH

cache="$HOME/.claude/usage-cache.json"
lock="$HOME/.claude/usage-cache.lock"

# Clear a lock left behind by a killed refresh (older than 5 minutes).
if [ -d "$lock" ]; then
  lock_mtime=$(stat -f %m "$lock" 2>/dev/null || stat -c %Y "$lock" 2>/dev/null || echo 0)
  if [ "$(( $(date +%s) - lock_mtime ))" -gt 300 ]; then
    rmdir "$lock" 2>/dev/null
  fi
fi

# mkdir is atomic: it fails if another refresh is already in flight.
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null' EXIT INT TERM

command -v claude >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Turn "Aug 7 at 7pm (Asia/Omsk)" into an epoch. The parenthesised zone is the one
# the timestamp is expressed in, and the year is absent, so it is filled from today
# and rolled forward if that lands in the past.
to_epoch() {
  _s=$1
  _tz=$(printf '%s' "$_s" | sed -n 's/.*(\(.*\))$/\1/p')
  _when=$(printf '%s' "$_s" | sed 's/ *(.*)$//; s/ at / /')
  _mon=$(printf '%s' "$_when" | awk '{print $1}')
  _day=$(printf '%s' "$_when" | awk '{print $2}')
  _tim=$(printf '%s' "$_when" | awk '{print $3}')
  [ -n "$_mon" ] && [ -n "$_day" ] && [ -n "$_tim" ] || return 1
  [ -n "$_tz" ] || _tz=$(date +%Z)
  _yr=$(date +%Y)
  _now=$(date +%s)
  # Seconds are pinned to 00; BSD date would otherwise inherit the current second.
  for _fmt in "%b %d %Y %I:%M%p %S" "%b %d %Y %I%p %S"; do
    _e=$(TZ="$_tz" date -j -f "$_fmt" "$_mon $_day $_yr $_tim 00" +%s 2>/dev/null)
    [ -n "$_e" ] || continue
    if [ "$_e" -lt "$(( _now - 86400 ))" ]; then
      _e=$(TZ="$_tz" date -j -f "$_fmt" "$_mon $_day $(( _yr + 1 )) $_tim 00" +%s 2>/dev/null)
    fi
    [ -n "$_e" ] || continue
    printf '%s' "$_e"
    return 0
  done
  return 1
}

# `/usage` resolves client-side: no API call, no tokens, no cost.
if command -v timeout >/dev/null 2>&1; then
  raw=$(timeout 60 claude -p "/usage" --output-format json 2>/dev/null | jq -r '.result // empty' 2>/dev/null)
else
  raw=$(claude -p "/usage" --output-format json 2>/dev/null | jq -r '.result // empty' 2>/dev/null)
fi
[ -n "$raw" ] || exit 0

max=0
note_max() {
  [ "$1" -gt "$max" ] && max=$1
  return 0
}

session_json="null"
session_line=$(printf '%s\n' "$raw" | grep -m1 'Current session:')
session_pct=$(printf '%s' "$session_line" | sed -n 's/.*Current session: \([0-9]*\)% used.*/\1/p')
if [ -n "$session_pct" ]; then
  note_max "$session_pct"
  session_reset=$(printf '%s' "$session_line" | sed -n 's/.*resets \(.*\)$/\1/p')
  session_epoch=$(to_epoch "$session_reset") || session_epoch=""
  session_json=$(jq -n \
    --argjson pct "$session_pct" \
    --arg reset_text "$session_reset" \
    --argjson reset_epoch "${session_epoch:-null}" \
    '{pct:$pct, reset_text:$reset_text, reset_epoch:$reset_epoch}')
fi

# One entry per weekly limit: "all models" plus any per-model caps.
weeks_json="[]"
weeks=$(printf '%s\n' "$raw" | sed -n 's/.*Current week (\([^)]*\)): \([0-9]*\)% used\(.*\)/\1|\2|\3/p')
old_ifs=$IFS
IFS='
'
for w in $weeks; do
  name=${w%%|*}
  rest=${w#*|}
  pct=${rest%%|*}
  tail_txt=${rest#*|}
  note_max "$pct"
  case "$name" in
    "all models") label="W" ;;
    *) label=$(printf '%s' "$name" | cut -c1 | tr '[:lower:]' '[:upper:]') ;;
  esac
  reset_text=$(printf '%s' "$tail_txt" | sed -n 's/.*resets \(.*\)$/\1/p')
  reset_epoch=""
  [ -n "$reset_text" ] && { reset_epoch=$(to_epoch "$reset_text") || reset_epoch=""; }
  weeks_json=$(printf '%s' "$weeks_json" | jq \
    --arg label "$label" \
    --arg name "$name" \
    --argjson pct "$pct" \
    --arg reset_text "$reset_text" \
    --argjson reset_epoch "${reset_epoch:-null}" \
    '. + [{label:$label, name:$name, pct:$pct, reset_text:$reset_text, reset_epoch:$reset_epoch}]')
done
IFS=$old_ifs

jq -n \
  --argjson fetched_at "$(date +%s)" \
  --argjson session "$session_json" \
  --argjson weeks "$weeks_json" \
  --argjson max_pct "$max" \
  --arg report "$raw" \
  '{fetched_at:$fetched_at, session:$session, weeks:$weeks, max_pct:$max_pct, report:$report}' \
  > "$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache" 2>/dev/null

# Drop the flat cache used before this script emitted JSON.
rm -f "$HOME/.claude/usage-cache.txt" 2>/dev/null
