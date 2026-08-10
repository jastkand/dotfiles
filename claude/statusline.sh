#!/bin/sh
# Claude Code status line.
# Shows: <model> (<effort>) | <cwd basename> | <git branch> | <ticket, if configured> | <usage>
#
# The ticket segment is an opt-in extension: without a config it never renders, and
# nothing else changes. See statusline.conf.example for the format. Lookup order:
#   1. $CLAUDE_STATUSLINE_TICKET_PREFIX / $CLAUDE_STATUSLINE_TICKET_URL from the environment
#   2. <git repo root>/.claude/statusline.conf   (or <cwd>/.claude/... outside a repo)
#   3. <main checkout>/.claude/statusline.conf   (only differs inside a linked worktree)
#   4. ~/.claude/statusline.conf                 (machine-wide default)
# The first source that yields a prefix wins; conf files are parsed as KEY=VALUE, never
# sourced, so dropping into an untrusted repo cannot execute anything.
#
# Ticket detection order, once a prefix is configured:
#   1. session_name field from the stdin payload (if Claude Code provides one)
#   2. git branch of workspace.current_dir
# The first case-insensitive match of <prefix>-[0-9]+ is uppercased into <PREFIX>-<n>.
#
# Effort detection order:
#   1. effort-related field in the stdin payload (.effort.level, or plain .effort / .effort_level / .model.effort)
#   2. "effortLevel" key in ~/.claude/settings.json

input=$(cat)
settings_file="$HOME/.claude/settings.json"

if command -v jq >/dev/null 2>&1; then
  model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
  cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
  session_name=$(printf '%s' "$input" | jq -r '.session_name // empty')
  effort=$(printf '%s' "$input" | jq -r '.effort.level // .effort // .effort_level // .model.effort // empty')
  if [ -z "$effort" ] && [ -f "$settings_file" ]; then
    effort=$(jq -r '.effortLevel // empty' "$settings_file" 2>/dev/null)
  fi
else
  # POSIX fallback if jq is unavailable.
  extract() {
    printf '%s' "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed -E "s/.*:\"(.*)\"/\1/"
  }
  model=$(extract display_name)
  cwd=$(extract current_dir)
  session_name=$(extract session_name)
  effort=$(extract level)
  [ -z "$effort" ] && effort=$(extract effort)
  [ -z "$effort" ] && effort=$(extract effort_level)
  if [ -z "$effort" ] && [ -f "$settings_file" ]; then
    effort=$(grep -o '"effortLevel"[[:space:]]*:[[:space:]]*"[^"]*"' "$settings_file" | head -1 | sed -E 's/.*:"(.*)"/\1/')
  fi
fi

if [ -n "$effort" ]; then
  model="$model ($effort)"
fi

base=""
[ -n "$cwd" ] && base=$(basename "$cwd" 2>/dev/null)

branch=""
repo_root=""
main_root=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  # Inside a linked worktree --show-toplevel is the worktree itself, which is created
  # without untracked files -- and statusline.conf is routinely gitignored, so it lives
  # only in the main checkout. --git-common-dir points at the main .git, and is absolute
  # exactly when the cwd is a linked worktree; from the main checkout it comes back
  # relative (".git", "../.git") and is skipped, since repo_root already covers that.
  common_dir=$(git -C "$cwd" --no-optional-locks rev-parse --git-common-dir 2>/dev/null)
  case "$common_dir" in
    /*) main_root=$(dirname "$common_dir") ;;
  esac
fi

# Read one KEY from a KEY=VALUE conf file. Blank lines, # comments, surrounding
# whitespace and one layer of quotes are tolerated.
conf_get() {
  [ -f "$2" ] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\(.*\)$/\1/p" "$2" 2>/dev/null \
    | head -1 \
    | sed -e 's/[[:space:]]*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/"
}

# Take TICKET_PREFIX from the first conf that defines one, and the URL from that same
# file so a half-configured conf cannot borrow the next one's link target. Written as
# calls rather than a `for` list because the worktree candidate is conditional, and an
# unquoted optional element would split a path containing spaces.
load_conf() {
  [ -n "$ticket_prefix" ] && return 0
  found=$(conf_get TICKET_PREFIX "$1")
  [ -n "$found" ] || return 0
  ticket_prefix="$found"
  ticket_url_tpl=$(conf_get TICKET_URL "$1")
}

ticket_prefix="$CLAUDE_STATUSLINE_TICKET_PREFIX"
ticket_url_tpl="$CLAUDE_STATUSLINE_TICKET_URL"
if [ -z "$ticket_prefix" ]; then
  load_conf "${repo_root:-$cwd}/.claude/statusline.conf"
  [ -n "$main_root" ] && load_conf "$main_root/.claude/statusline.conf"
  load_conf "$HOME/.claude/statusline.conf"
fi

# Find a <PREFIX>-<number> ticket, preferring the session name over the branch.
ticket=""
if [ -n "$ticket_prefix" ]; then
  prefix_up=$(printf '%s' "$ticket_prefix" | tr '[:lower:]' '[:upper:]')
  for src in "$session_name" "$branch"; do
    # 2>/dev/null: a prefix with regex metacharacters makes grep complain rather
    # than match, and the ticket segment should degrade quietly instead.
    match=$(printf '%s' "$src" | grep -Eio "$ticket_prefix-[0-9]+" 2>/dev/null | head -1)
    if [ -n "$match" ]; then
      num=$(printf '%s' "$match" | grep -Eo '[0-9]+')
      ticket="$prefix_up-$num"
      break
    fi
  done
fi

# Shorten an over-long branch for display. Done after ticket detection so the
# ticket lookup still sees the full name.
branch_max=128
if [ "${#branch}" -gt "$branch_max" ]; then
  branch=$(printf "%.${branch_max}s" "$branch")
  # Back off to the last word boundary so the name does not end mid-word, but keep
  # the hard cut when the nearest boundary would throw away too much.
  case "$branch" in
    *[-_/.]*)
      trimmed="${branch%[-_/.]*}"
      [ "${#trimmed}" -ge "$(( branch_max * 2 / 3 ))" ] && branch="$trimmed"
      ;;
  esac
  branch="${branch%[-_/.]}..."
fi

# Usage limits, read from a cache that a background job refreshes.
# Rendering never waits on it: a stale cache is shown as-is while the refresh runs,
# so the numbers can lag one render behind.
usage_cache="$HOME/.claude/usage-cache.json"
usage_ttl=60
usage=""
usage_age=$usage_ttl
if [ -f "$usage_cache" ]; then
  cache_mtime=$(stat -f %m "$usage_cache" 2>/dev/null || stat -c %Y "$usage_cache" 2>/dev/null || echo 0)
  usage_age=$(( $(date +%s) - cache_mtime ))
  if command -v jq >/dev/null 2>&1; then
    # Each percentage is coloured on its own: under 70 plain, 70 through 90 yellow,
    # above 90 red. The reset countdown always stays plain.
    # The countdown is derived here rather than at fetch time, so it keeps ticking
    # down between refreshes instead of freezing at the cached value.
    esc=$(printf '\033')
    usage=$(jq -r \
      --argjson now "$(date +%s)" \
      --arg plain "$esc[0m" \
      --arg warn "$esc[33m" \
      --arg crit "$esc[31m" '
      def hm($s):
        if $s >= 3600 then "\($s / 3600 | floor)h\(($s % 3600) / 60 | floor)m"
        else "\([$s / 60 | floor, 1] | max)m" end;
      def col($p): if $p > 90 then $crit elif $p >= 70 then $warn else $plain end;
      ([ (.session // empty)
         | col(.pct) + "S:\(.pct)%" + $plain
           + (if (.reset_epoch != null) and (.reset_epoch > $now)
              then " (\(hm(.reset_epoch - $now)))" else "" end) ]
       + [ .weeks[]? | col(.pct) + "\(.label):\(.pct)%" + $plain ])
      | join(" · ")
    ' "$usage_cache" 2>/dev/null)
  fi
fi
if [ "$usage_age" -ge "$usage_ttl" ] && [ -f "$HOME/.claude/usage-refresh.sh" ]; then
  (sh "$HOME/.claude/usage-refresh.sh" >/dev/null 2>&1 &) >/dev/null 2>&1
fi

line="$model"
[ -n "$base" ] && line="$line | $base"
[ -n "$branch" ] && line="$line | $branch"
if [ -n "$ticket" ]; then
  ticket_url=""
  case "$ticket_url_tpl" in
    *'{ticket}'*) ticket_url=$(printf '%s' "$ticket_url_tpl" | sed "s|{ticket}|$ticket|g") ;;
  esac
  if [ -n "$ticket_url" ]; then
    # OSC 8 hyperlink: the ticket id renders as clickable text pointing at the tracker.
    # Terminals without OSC 8 support ignore the sequence and show the bare id.
    line="$line | $(printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$ticket_url" "$ticket")"
  else
    line="$line | $ticket"
  fi
fi
[ -n "$usage" ] && line="$line | $usage"

printf '%s' "$line"
