#!/bin/sh
# Tests for statusline.sh and patch-settings.sh.
#
# Run with `make test-claude`, or directly: sh claude/statusline_test.sh
# Needs git and jq. Everything happens in a temp dir under a fake $HOME, so the
# real ~/.claude is neither read nor written.
#
# Escape sequences are normalised through `cat -v`, so ESC shows up as ^[ and the
# expectations below stay readable.

set -u

here=$(cd "$(dirname "$0")" && pwd)
sl="$here/statusline.sh"
patch="$here/patch-settings.sh"

for dep in git jq; do
  command -v "$dep" >/dev/null 2>&1 || { echo "statusline_test: $dep is required"; exit 2; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

HOME="$tmp/home"
export HOME
mkdir -p "$HOME/.claude"

repo="$tmp/repo"
mkdir -p "$repo/.claude"
git -C "$repo" init -q
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name "statusline test"
git -C "$repo" checkout -q -b feature/proj-1234-add-thing 2>/dev/null
# An empty commit makes the branches real refs, so tests can switch back and forth.
git -C "$repo" commit -q --allow-empty -m init

global_conf="$HOME/.claude/statusline.conf"
repo_conf="$repo/.claude/statusline.conf"

pass=0
fail=0

# ---- helpers ----------------------------------------------------------------

no_conf() { rm -f "$global_conf" "$repo_conf"; }

# render <json payload>
render() { printf '%s' "$1" | sh "$sl" | cat -v; }

payload_repo='{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"'"$repo"'"}}'

# A ticket rendered as an OSC 8 hyperlink, as `cat -v` shows it.
link() { printf '^[]8;;%s^[\\%s^[]8;;^[\\' "$1" "$2"; }

report() { # <desc> <expected> <actual> <ok?>
  if [ "$4" = y ]; then
    pass=$((pass + 1))
    printf '  ok    %s\n' "$1"
  else
    fail=$((fail + 1))
    printf '  FAIL  %s\n        expected: %s\n        actual:   %s\n' "$1" "$2" "$3"
  fi
}

is() { # <desc> <expected> <actual>
  if [ "$3" = "$2" ]; then report "$1" "$2" "$3" y; else report "$1" "$2" "$3" n; fi
}

like() { # <desc> <extended regex> <actual>
  # grep rather than `case`, deliberately: zsh does not glob-expand a case pattern
  # that comes from a variable, so a glob here would silently never match when the
  # suite is run as `zsh statusline_test.sh`.
  if printf '%s' "$3" | grep -Eq -- "$2"; then
    report "$1" "$2" "$3" y
  else
    report "$1" "$2" "$3" n
  fi
}

base_line="Opus 5 | repo | feature/proj-1234-add-thing"

# ---- the ticket extension is opt-in ----------------------------------------

echo "ticket extension: absent or incomplete config hides the link"

no_conf
is "no config anywhere: no ticket segment" \
  "$base_line" "$(render "$payload_repo")"

printf 'TICKET_URL=https://tracker.example/{ticket}\n' > "$global_conf"
is "URL but no prefix: no ticket segment" \
  "$base_line" "$(render "$payload_repo")"

printf 'TICKET_PREFIX=\nTICKET_URL=https://tracker.example/{ticket}\n' > "$global_conf"
is "empty prefix value: no ticket segment" \
  "$base_line" "$(render "$payload_repo")"

printf 'TICKET_PREFIX=PROJ\n' > "$global_conf"
is "prefix but no URL: bare id, no link" \
  "$base_line | PROJ-1234" "$(render "$payload_repo")"

printf 'TICKET_PREFIX=PROJ\nTICKET_URL=\n' > "$global_conf"
is "empty URL value: bare id, no link" \
  "$base_line | PROJ-1234" "$(render "$payload_repo")"

printf 'TICKET_PREFIX=PROJ\nTICKET_URL=https://tracker.example/browse\n' > "$global_conf"
is "URL without {ticket}: bare id, no broken link" \
  "$base_line | PROJ-1234" "$(render "$payload_repo")"

printf 'TICKET_PREFIX=NOPE\nTICKET_URL=https://tracker.example/{ticket}\n' > "$global_conf"
is "prefix does not match the branch: no ticket segment" \
  "$base_line" "$(render "$payload_repo")"

printf 'TICKET_PREFIX=*\nTICKET_URL=https://tracker.example/{ticket}\n' > "$global_conf"
is "prefix with regex metacharacters degrades quietly" \
  "$base_line" "$(render "$payload_repo")"

# ---- a complete config links ------------------------------------------------

echo "ticket extension: complete config links"

printf 'TICKET_PREFIX=PROJ\nTICKET_URL=https://tracker.example/{ticket}\n' > "$global_conf"
is "global conf: hyperlinked id" \
  "$base_line | $(link https://tracker.example/PROJ-1234 PROJ-1234)" \
  "$(render "$payload_repo")"

printf '# comment\n  TICKET_PREFIX = proj  \nTICKET_URL="https://repo.example/browse/{ticket}"\n' > "$repo_conf"
is "repo conf wins over global, tolerating quotes and whitespace" \
  "$base_line | $(link https://repo.example/browse/PROJ-1234 PROJ-1234)" \
  "$(render "$payload_repo")"

printf 'TICKET_URL=https://repo.example/browse/{ticket}\n' > "$repo_conf"
is "repo conf without a prefix falls back to the global conf" \
  "$base_line | $(link https://tracker.example/PROJ-1234 PROJ-1234)" \
  "$(render "$payload_repo")"

rm -f "$repo_conf"
is "env vars override the conf files" \
  "$base_line | $(link https://env.example/PROJ-1234 PROJ-1234)" \
  "$(CLAUDE_STATUSLINE_TICKET_PREFIX=proj \
     CLAUDE_STATUSLINE_TICKET_URL=https://env.example/{ticket} \
     render "$payload_repo")"

is "env prefix alone: bare id, conf URL is not mixed in" \
  "$base_line | PROJ-1234" \
  "$(CLAUDE_STATUSLINE_TICKET_PREFIX=proj render "$payload_repo")"

is "session_name is preferred over the branch" \
  "Opus 5 (high) | repo | feature/proj-1234-add-thing | $(link https://tracker.example/PROJ-9999 PROJ-9999)" \
  "$(render '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"'"$repo"'"},"session_name":"PROJ-9999 hotfix","effort":{"level":"high"}}')"

# A conf is data, never code: dropping into an untrusted repo must not run anything.
printf 'TICKET_PREFIX=PROJ\nTICKET_URL=https://tracker.example/{ticket}\nEVIL=$(touch %s/pwned)\n`touch %s/pwned2`\n' "$tmp" "$tmp" > "$repo_conf"
render "$payload_repo" >/dev/null
if [ -e "$tmp/pwned" ] || [ -e "$tmp/pwned2" ]; then
  report "conf values are parsed, not executed" "no files created" "conf executed code" n
else
  report "conf values are parsed, not executed" "no files created" "no files created" y
fi
rm -f "$repo_conf"

# ---- the rest of the line ---------------------------------------------------

echo "other segments"

no_conf
is "outside a git repo: no branch, no ticket" \
  "Opus 5 | tmp" \
  "$(render '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"/tmp"}}')"

is "no cwd in the payload: model only" \
  "Opus 5" \
  "$(render '{"model":{"display_name":"Opus 5"}}')"

is "effort comes from the payload" \
  "Opus 5 (max) | tmp" \
  "$(render '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"/tmp"},"effort":{"level":"max"}}')"

printf '{"effortLevel":"low"}\n' > "$HOME/.claude/settings.json"
is "effort falls back to settings.json" \
  "Opus 5 (low) | tmp" \
  "$(render '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"/tmp"}}')"
rm -f "$HOME/.claude/settings.json"

long=$(printf 'feature/%s' "$(awk 'BEGIN{while(i++<40)printf "chunk-"}')")
git -C "$repo" checkout -q -b "$long" 2>/dev/null
like "an over-long branch is truncated with an ellipsis" \
  '^Opus 5 \| repo \| feature/(chunk-?)+\.\.\.$' \
  "$(render "$payload_repo")"
git -C "$repo" checkout -q feature/proj-1234-add-thing 2>/dev/null

# Usage segment: a fresh cache renders, colour-coded per window.
jq -n --argjson reset "$(( $(date +%s) + 7200 ))" \
  '{fetched_at:0, session:{pct:95, reset_text:"x", reset_epoch:$reset},
    weeks:[{label:"W", name:"all models", pct:72, reset_text:"x", reset_epoch:$reset},
           {label:"O", name:"opus", pct:10, reset_text:"x", reset_epoch:$reset}],
    max_pct:95, report:""}' > "$HOME/.claude/usage-cache.json"
like "usage segment renders, coloured red above 90 and yellow at 70+" \
  '\| \^\[\[31mS:95%\^\[\[0m \([0-9]+h[0-9]+m\) · \^\[\[33mW:72%\^\[\[0m · \^\[\[0mO:10%\^\[\[0m$' \
  "$(render "$payload_repo")"
rm -f "$HOME/.claude/usage-cache.json"

# ---- patch-settings.sh ------------------------------------------------------

echo "patch-settings.sh"

settings="$tmp/settings.json"
rm -f "$settings"
sh "$patch" "$settings" >/dev/null
is "creates a missing settings.json with the statusLine key" \
  "sh ~/.claude/statusline.sh" \
  "$(jq -r '.statusLine.command' "$settings")"

printf '{"theme":"dark","model":"opus[1m]"}\n' > "$settings"
sh "$patch" "$settings" >/dev/null
is "preserves unrelated keys" \
  "dark opus[1m] command" \
  "$(jq -r '[.theme, .model, .statusLine.type] | join(" ")' "$settings")"

before=$(cat "$settings")
sh "$patch" "$settings" >/dev/null
is "is idempotent" "$before" "$(cat "$settings")"

printf '{oops' > "$settings"
sh "$patch" "$settings" >/dev/null 2>&1
rc=$?   # not `status`: that name is read-only in zsh
is "refuses invalid JSON with a non-zero exit" "1" "$rc"
is "leaves invalid JSON untouched" "{oops" "$(cat "$settings")"

# ---- summary ----------------------------------------------------------------

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
