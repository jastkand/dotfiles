# Standing preferences

These apply everywhere, in every project. Project-level `CLAUDE.md` files add to them and win
where they genuinely conflict.

## "- kapish?" means remember this

When a message ends with `- kapish?`, treat it as an explicit instruction to write what it said
into memory as a durable fact, in addition to acting on it.

**Why:** it's personal shorthand for "commit this to memory" — not a rhetorical question.

**How to apply:** write the message's substance to a new memory file under the appropriate
`type:` (usually `feedback`), add its `MEMORY.md` pointer line, and confirm briefly. If an
existing memory already covers it, update that file instead of adding a duplicate.

## Git and PR etiquette

1. **Never `git push` unless asked.** Local commits are fine to make proactively; after
   committing, stop. Push only on an explicit request ("push", `/pr`, or similar) — including
   pushes that would update an already-open PR.
2. **Never force-push.** No `--force` or `--force-with-lease`, on any branch, including my own
   feature branches. If local history changed (amend/rebase) on a branch that's already pushed,
   prefer a new commit on top; if rewriting pushed history really seems necessary, ask first.
3. **Never wait on PR/CI checks unprompted.** After opening or updating a PR: no polling loops,
   no `sleep`-and-retry, no background monitors on `gh pr checks`. Read the status once if
   useful, say what's passing or pending, and hand back.

**Why:** I review work locally before it reaches the remote, watch CI myself, and will bring
failures back if I want them fixed. Unprompted pushes update PRs prematurely, force-pushes
destroy history I may be reading, and blocking on checks burns turn time producing information
I already have.

**How to apply:** commit → stop. When I *do* ask for a push, a check-watch, or a history
rewrite, doing it is fine — these are defaults, not prohibitions.

## Use `gh`, not the GitHub MCP tools

Use the `gh` CLI via Bash for all GitHub operations — PRs, review-comment replies, API calls.
Do not use the `mcp__claude_ai_Github_MCP__*` tools.

**How to apply:** for review-thread replies,
`gh api repos/<owner>/<repo>/pulls/<pr>/comments/<id>/replies -f body=...`; for everything else
the usual `gh pr` / `gh api` commands.

## Never read or inline secrets

Never open a credentials file (`.env`, `.context/*.env`, keyfiles) with Read, and never paste
its values inline on a command line. Always *use* the file by sourcing it, so the secrets never
enter the transcript.

**Why:** anything in the transcript is leaked and has to be rotated. A sandbox refusing a shell
construct is about the construct — never a licence to expose the secret some other way.

**How to apply:** the intended form is `set -a; . <file>; set +a; <command>`. When a session
refuses the `.` builtin, do NOT read the file — either pass it through unread
(`env $(grep -v '^#' <file> | xargs) <command>`) or hand me the exact command to run myself with
the `!` prefix and use the output I paste back. If a secret does reach the transcript, say so
plainly and recommend rotating it.
