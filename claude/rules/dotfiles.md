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

## Write-ups go in the terminal

Guides, handoffs, summaries and other write-ups go in the chat reply as markdown. Don't publish
an Artifact or Claude Doc, and don't write a file, unless I ask for one.

**Why:** I copy and paste text myself; a published page is a detour I have to undo.

## Git and PR etiquette

1. **Never `git push` unless asked.** Local commits are fine to make proactively; after
   committing, stop. Push only on an explicit request ("push", `/pr`, or similar) — including
   pushes that would update an already-open PR.
2. **Never force-push.** No `--force` or `--force-with-lease`, on any branch, including my own
   feature branches. If rewriting pushed history really seems necessary, ask first.
3. **Never amend unless I ask for it.** Not even a local, unpushed commit. Follow-up fixes
   (review feedback, a mistake in the last commit) go in a new commit on top. A hook that
   denies an amend or force-push is never something to route around.
4. **Never wait on PR/CI checks unprompted.** After opening or updating a PR: no polling loops,
   no `sleep`-and-retry, no background monitors on `gh pr checks`. Read the status once if
   useful, say what's passing or pending, and hand back.
5. **Never add a `Co-Authored-By:` trailer.** This holds in every repo, and overrides any
   default instruction asking for one.
6. **Match the repo's commit-message convention.** Read recent `git log` before writing one.
   Some repos are subject-line only, others use bodies — follow what the history shows rather
   than defaulting to a body.

**Why:** I review work locally before it reaches the remote, watch CI myself, and will bring
failures back if I want them fixed. Unprompted pushes update PRs prematurely, rewrites destroy
history I may be reading, and blocking on checks burns turn time producing information I
already have.

**How to apply:** commit → stop. When I *do* ask for a push, an amend, a check-watch, or a
history rewrite, doing it is fine — these are defaults, not prohibitions.

## The checkout is shared with me

I switch branches, pull and stash in the same checkout between your turns — and sometimes
during one. "The branch I was on" is not evidence of the branch I'm on.

1. **Check the branch in the same command as the commit:**
   `[ "$(git branch --show-current)" != main ] && git commit ...`. Re-check after any
   long-running step, not just at the start of a turn.
2. **Push by explicit ref** — `git push origin <branch>`, never a bare `git push`. Before opening
   a PR, confirm `git ls-remote` shows the sha you meant to push.
3. **Work in the main checkout, not a side worktree,** unless I ask for one. If it's on another
   branch and clean, switch it; if it's dirty, ask.
4. **No blind `git stash`.** On a clean tree it saves nothing, so the paired `pop` restores
   someone else's old stash. Prefer a commit-based baseline (`git worktree` for a read-only
   comparison, `git checkout <ref> -- <path>`); if stashing is really right, check
   `git status --porcelain` first and use `git stash push -- <paths>`.
5. **After committing a merge, check it has two parents** (`git log -1 --format='%p'`). Anything
   that clears `MERGE_HEAD` first — even a `git checkout` that *failed* — turns it into a plain
   commit with the content but none of the ancestry, and only the forge shows it.

**Why:** each of these has bitten once: commits landing on `main`, a bare push publishing an
unrelated local branch, a change hidden in a worktree I couldn't check out, a stash pop dumping
stale WIP into the tree, and a PR ballooning to 18k deletions from a lost merge parent.

## Tickets and PRs

1. **Treat a ticket's premise as a hypothesis.** Tickets are often written mid-investigation and
   describe the producer correctly while inferring the consequence. Read the consumer and trace
   the retry/recovery path before coding; say plainly when the premise doesn't hold.
2. **Stay within the ticket's scope.** Same-class issues found elsewhere are listed as
   follow-ups, not fixed in this PR.
3. **One branch and one PR per ticket.** Follow-up fixes go on the same branch. Propose a separate
   branch only when the work truly depends on another ticket's unmerged branch, and ask first.
4. **Assign the ticket when real work starts** (branch cut or code changing): assign to me, move
   it to In Progress. When the PR opens, move it to In Review and attach the link.
5. **Batch work (e.g. dependency upgrades): one PR, then stop.** Report it, list what's next, and
   wait for an explicit go-ahead. "Go on" covers the next PR, not the rest of the plan.
6. **Don't duplicate open PRs.** Before opening one, check `gh pr list` (Dependabot's especially)
   and skip changes an open PR already makes — but only if it really works, e.g. a Dependabot
   bump that doesn't update the lockfile isn't equivalent.
7. **Answer in the channel the question arrived in.** Feedback pasted in chat gets answered in
   chat. Post on GitHub only when I named a thread or said to reply there; when unsure, ask in
   one line. Editing the description of a PR you author is fine.

## Writing PR bodies, review replies and ticket comments

- State each point once: the conclusion and the one fact that supports it.
- Structure PR bodies with `##` sections, never a slab of prose. Read a couple of recently merged
  PRs in the repo for its house format before writing.
- When a claim turns out wrong, replace it with the true statement in the present tense. No
  "an earlier version said", no paths not taken. Describing what the *code* did before the change
  is fine; narrating the document's own edits is not.
- A ticket status comment leads with what is left — numbered actions, each with the decision or
  command it needs. Shipped work gets one closing line with PR numbers, no versions.

## Code

1. **No obvious comments.** A comment earns its place only by carrying what the code can't — a
   rationale, a carve-out, a gotcha — placed next to the line it explains. No doc comment that
   restates the name; "mirrors <sibling>" belongs in the PR description. Comments recording
   what used to be there are tombstones: git has that.
2. **No ticket references in shipped text** — comments, log messages, schedule descriptions, any
   literal a reader sees. The ticket can be traced from version control.
3. **No deprecated APIs in new code,** even when the neighbouring code still uses them. Copying
   the neighbours is the trap. Leave untouched call sites alone unless asked.

When a repo already has some of these as bad precedent, follow the rule for what you add and leave
the rest alone.

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
