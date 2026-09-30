# Claude Usage Limits

Report my current Claude subscription usage limits. Named `my-usage` because `/usage` is a
built-in CLI dialog whose output never reaches the model — this reads the same report through
`~/.claude/usage-refresh.sh`, the helper that also feeds the statusline.

## Steps

1. Refresh the cache and print everything you need in one shot:
```
sh ~/.claude/usage-refresh.sh; jq -r --argjson now "$(date +%s)" '
  def hm($s):
    if $s < 0 then "already reset"
    else (($s / 86400) | floor) as $d
      | ((($s % 86400) / 3600) | floor) as $h
      | ((($s % 3600) / 60) | floor) as $m
      | if $d > 0 then "in \($d)d \($h)h" elif $h > 0 then "in \($h)h \($m)m" else "in \($m)m" end
    end;
  "cache age: \($now - .fetched_at)s",
  ((.session // empty)
    | "Current session\t\(.pct)%\t\(.reset_text)\t\(if .reset_epoch then hm(.reset_epoch - $now) else "unknown" end)"),
  (.weeks[]?
    | "Current week (\(.name))\t\(.pct)%\t\(.reset_text)\t\(if .reset_epoch then hm(.reset_epoch - $now) else "unknown" end)"),
  "--- full report ---",
  .report
' ~/.claude/usage-cache.json
```
This costs nothing — `/usage` resolves client-side, so no API call and no tokens. The refresh
takes about 3s, and no-ops instantly if another session holds the lock. Never spawn a subagent
for it.

2. Render the tab-separated limit lines as a table: window, percent used, reset time, time from
now. The countdowns are already computed above — use them verbatim, do not recalculate from the
wall-clock reset text.

3. Below the table, summarize the "what's contributing" section of the full report — last 24h and
last 7d request and session counts, plus whichever behaviors, skills, subagents, and MCP servers
carry meaningful percentages. Skip the long tail of sub-1% entries.

4. Call out the tightest window (highest percent used), since that is the one that will actually
throttle me, and note when it is a per-model limit rather than the all-models one.

5. Keep two caveats: the contribution breakdown is approximate and covers only local sessions on
this machine (not claude.ai, not other devices), and it aggregates all my concurrent sessions
rather than just this one.

6. If `cache age` comes back over ~120s, another session was mid-refresh and the numbers are that
old — say so alongside the table.

If the cache file is missing or jq errors, fall back to reading the report directly:
```
claude -p "/usage" --output-format json | jq -r .result
```
If that also fails, say so plainly and show the raw output rather than guessing at numbers. Never
estimate usage percentages from any other source.

When Claude is configured against Z.ai (`ANTHROPIC_BASE_URL` at api.z.ai or open.bigmodel.cn),
the cache is filled from Z.ai's quota endpoint instead of `/usage`: `.session` is the shortest
GLM quota window (5h on current plans), `.weeks` holds the longer ones, and `.report` is the raw
quota JSON rather than /usage text. Render the table from `.session`/`.weeks` alone, skip steps
3–5, and do not use the fallback above — with a Z.ai token there is no Anthropic subscription
for `/usage` to report on.
