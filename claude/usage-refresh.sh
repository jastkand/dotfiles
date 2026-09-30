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
#
# When ANTHROPIC_BASE_URL points at Z.ai (api.z.ai, open.bigmodel.cn) there is no
# Anthropic subscription for `/usage` to read, so the numbers come from Z.ai's own
# quota endpoint instead: GET https://<api host>/api/monitor/usage/quota/limit with
# the same auth token — undocumented, but the data behind their Usage Statistics
# page. The cache shape is unchanged: the shortest quota window (5h on GLM plans)
# fills "session", longer ones fill "weeks" with a unit-initial label, and .report
# holds the raw response JSON rather than /usage text.

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

command -v jq >/dev/null 2>&1 || exit 0

settings_file="$HOME/.claude/settings.json"

# Read one env override out of settings.json. Values there are what a fresh
# `claude` start would use; the process environment, when set, wins below.
settings_env() {
  [ -f "$settings_file" ] || return 0
  jq -r --arg k "$1" '.env[$k] // empty' "$settings_file" 2>/dev/null
}

# write_cache <session_json> <weeks_json> <max_pct> <report>
write_cache() {
  jq -n \
    --argjson fetched_at "$(date +%s)" \
    --argjson session "$1" \
    --argjson weeks "$2" \
    --argjson max_pct "$3" \
    --arg report "$4" \
    '{fetched_at:$fetched_at, session:$session, weeks:$weeks, max_pct:$max_pct, report:$report}' \
    > "$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache" 2>/dev/null
}

# Z.ai GLM Coding Plan usage. Returns 1 when Claude is not pointed at Z.ai,
# 0 once the cache has been written (or the attempt failed conclusively).
refresh_zai() {
  base_url=${ANTHROPIC_BASE_URL:-$(settings_env ANTHROPIC_BASE_URL)}
  case "$base_url" in
    *api.z.ai/*|*bigmodel.cn/*) : ;;
    *) return 1 ;;
  esac
  command -v curl >/dev/null 2>&1 || return 0

  # The quota endpoint lives on the API host, so the international and China
  # regions both work without hardcoding either one.
  api_host=$(printf '%s' "$base_url" | sed -E 's#^[a-z]+://([^/]+).*#\1#')

  token=${ANTHROPIC_AUTH_TOKEN:-$(settings_env ANTHROPIC_AUTH_TOKEN)}
  [ -n "$token" ] || return 0

  # The token reaches curl through a config read on stdin, not a command-line
  # argument, so it never shows up in argv.
  raw=$(printf 'header = "authorization: Bearer %s"\n' "$token" \
    | curl -sS -K - --max-time 15 -H "accept: application/json" \
        "https://$api_host/api/monitor/usage/quota/limit" 2>/dev/null) || return 0
  printf '%s' "$raw" | jq -e '.success == true' >/dev/null 2>&1 || return 0

  # Each limit is one quota window: unit codes 1/3/5/6 mean day/hour/minute/
  # week, number is how many of those per window, percentage how much is used.
  # TIME_LIMIT is the MCP tool-call lane, not token usage, and is dropped. The
  # shortest window takes the session slot the way the 5-hour limit does for
  # Anthropic subscriptions; the rest are labelled with their unit's initial.
  rows=$(printf '%s' "$raw" | jq -r '
    def mins: {"1":1440,"3":60,"5":1,"6":10080}[(.unit|tostring)];
    def uname: {"1":"day","3":"hour","5":"minute","6":"week"}[(.unit|tostring)] // "window";
    [ (.data.limits // [])[]
      | select(.type != "TIME_LIMIT")
      | mins as $m | select($m and (.percentage | type == "number"))
      | uname as $u
      | {min: ($m * .number),
         label: ($u | .[0:1] | ascii_upcase),
         name: "\(.number) \($u) window",
         pct: .percentage,
         epoch: (((.nextResetTime // 0) / 1000) | floor)}
    ] | sort_by(.min)
    | .[] | [.min, .label, .name, .pct, .epoch] | @tsv
  ' 2>/dev/null)

  now=$(date +%s)
  session_json="null"
  weeks_json="[]"
  max=0
  i=0
  old_ifs=$IFS
  IFS='
'
  for r in $rows; do
    min=$(printf '%s' "$r" | cut -f1)
    label=$(printf '%s' "$r" | cut -f2)
    name=$(printf '%s' "$r" | cut -f3)
    pct=$(printf '%s' "$r" | cut -f4)
    epoch=$(printf '%s' "$r" | cut -f5)
    case "$pct" in ''|*[!0-9]*) continue ;; esac
    # A 5-hour reset reported further out than 5h+1m is a timezone bug on the
    # API side (CodexBar guards the same way); show no countdown rather than a
    # wrong one. An epoch of 0 means the API sent no reset time at all.
    if [ "$min" = 300 ] && [ "$epoch" -gt "$(( now + 18120 ))" ]; then
      epoch=""
    fi
    [ "$epoch" = 0 ] && epoch=""
    reset_text=""
    [ -n "$epoch" ] && reset_text=$(date -r "$epoch" "+%b %d at %H:%M (%Z)" 2>/dev/null)
    [ "$pct" -gt "$max" ] && max=$pct
    if [ "$i" = 0 ] && [ "$min" -lt 1440 ]; then
      session_json=$(jq -n \
        --argjson pct "$pct" \
        --arg reset_text "$reset_text" \
        --argjson reset_epoch "${epoch:-null}" \
        '{pct:$pct, reset_text:$reset_text, reset_epoch:$reset_epoch}')
    else
      weeks_json=$(printf '%s' "$weeks_json" | jq \
        --arg label "$label" \
        --arg name "$name" \
        --argjson pct "$pct" \
        --arg reset_text "$reset_text" \
        --argjson reset_epoch "${epoch:-null}" \
        '. + [{label:$label, name:$name, pct:$pct, reset_text:$reset_text, reset_epoch:$reset_epoch}]')
    fi
    i=$(( i + 1 ))
  done
  IFS=$old_ifs

  # The full response, pretty-printed for the /my-usage skill.
  report=$(printf '%s' "$raw" | jq . 2>/dev/null) || report=$raw

  write_cache "$session_json" "$weeks_json" "$max" "$report"
  return 0
}

if refresh_zai; then
  # Drop the flat cache used before this script emitted JSON.
  rm -f "$HOME/.claude/usage-cache.txt" 2>/dev/null
  exit 0
fi

command -v claude >/dev/null 2>&1 || exit 0

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

write_cache "$session_json" "$weeks_json" "$max" "$raw"

# Drop the flat cache used before this script emitted JSON.
rm -f "$HOME/.claude/usage-cache.txt" 2>/dev/null
