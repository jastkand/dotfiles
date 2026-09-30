## Install

```sh
make bootstrap      # fresh machine: brew packages, then configs
make                # configs only (vim + claude + git + zsh)
make install-claude
make install-git    # ~/.gitignore_global, plus an include.path entry so this repo's
                    # .gitconfig applies. ~/.gitconfig itself is never overwritten:
                    # identity, gpg and lfs settings are machine-local
make install-zsh    # a ~/.zshrc that sources this repo's .zshrc. Same idea: ~/.zshrc
                    # itself is never overwritten, tool installers keep appending to it
make check-brew     # what the Brewfile wants that is not installed yet
make install-brew   # installs only what is missing, never upgrades
make test
```

`Brewfile` lists the tools these configs assume — nothing is version-pinned there, and
there is no `.tool-versions`: asdf keeps runtime versions in each project. GUI apps are
listed but commented out, since brew will not take over an app installed by hand; see the
notes in the file.

## Claude Code

```sh
make install-claude
```

Copies into `~/.claude/`:

- `rules/dotfiles.md` — standing preferences, loaded into every session in every project
- `statusline.sh` — `<model> (<effort>) | <dir> | <branch> | <ticket> | <usage>`
- `usage-refresh.sh` — background helper caching `/usage` into `~/.claude/usage-cache.json`
  (or the Z.ai quota endpoint, when `ANTHROPIC_BASE_URL` points at Z.ai)
- `commands/my-usage.md` — `/my-usage`, reads that cache and reports subscription limits

`settings.json` is not overwritten: only its `statusLine` key is patched in with `jq`, so
`model`, `theme`, `effortLevel` and `enabledPlugins` stay machine-local. Requires `jq`.

### Standing preferences

`claude/rules/dotfiles.md` holds the rules that should hold everywhere — git/PR etiquette, `gh`
over the GitHub MCP tools, never reading or inlining secrets, and what `- kapish?` means.

It installs to `~/.claude/rules/dotfiles.md`. User-level rules load unconditionally in every
project, the same as `~/.claude/CLAUDE.md` would, but keep the two concerns apart: this file is
**overwritten wholesale** on every `make install-claude` (edit it here, not there), while
`~/.claude/CLAUDE.md` is never written by this repo and stays free for machine-local notes.
Rules that only apply to one codebase belong in that repo's own `CLAUDE.md`.

Not to be confused with `~/.claude/projects/<project>/memory/`: those files are per-project,
written by Claude as it works, and not managed by this repo.

### Ticket extension (opt-in)

The ticket segment renders nothing until configured, so the statusline is safe to install
anywhere. To turn it on, copy `claude/statusline.conf.example` to either scope:

| Path | Scope |
| --- | --- |
| `<repo>/.claude/statusline.conf` | per project — wins over everything below |
| `<main checkout>/.claude/statusline.conf` | reached from inside a linked worktree |
| `~/.claude/statusline.conf` | machine-wide fallback |

The middle row matters because `git worktree add` only populates tracked files, and this
config is usually gitignored — so a worktree starts without one and would otherwise show no
ticket at all. The lookup falls back to the main checkout via `git rev-parse --git-common-dir`,
while a conf placed inside the worktree still wins if you want to override it there.

```sh
TICKET_PREFIX=PROJ
TICKET_URL=https://linear.app/your-workspace/issue/{ticket}
```

The prefix is matched case-insensitively against the session name first, then the git branch —
`feature/proj-1234-add-thing` becomes a clickable `PROJ-1234`. Drop `TICKET_URL` to show the bare
id. `CLAUDE_STATUSLINE_TICKET_PREFIX` / `CLAUDE_STATUSLINE_TICKET_URL` override both files.

`TICKET_PREFIX` also takes a comma-separated list — `TICKET_PREFIX=PROJ,ENG` — for a repo whose
branches carry keys from more than one project. All of them share the single `TICKET_URL`, which
is what trackers like Linear and Jira want anyway, since only the project key differs. When a
branch mentions two of them, the one appearing first in the branch wins, not the one listed
first in the conf.
Conf files are parsed as `KEY=VALUE`, never sourced, so an untrusted repo's config cannot
execute anything.

Anything missing degrades quietly, never into a broken link: no config, no prefix, or a prefix
that doesn't match the branch hides the segment entirely; a prefix with no usable `TICKET_URL`
shows the plain id.

### Tests

```sh
make test   # == make test-claude
```

`claude/statusline_test.sh` renders the statusline against a fake `$HOME` and a throwaway git
repo, covering the config precedence chain, every incomplete-config case, and `patch-settings.sh`.
It touches nothing outside its temp dir.

## ZSH

```sh
make install-zsh
```

`~/.zshrc` is never overwritten -- for the same reason `~/.gitconfig` is not. Tool
installers (asdf, bun, LM Studio, the odd `curl | sh`) append their own blocks to it, and
those are machine-local by nature: they hardcode paths that exist on one machine. Fighting
that with a copied file means losing those blocks on every `make`.

So `~/.zshrc` becomes a stub whose real job is to pull in this repo's `.zshrc`:

```zsh
source /path/to/dotfiles/.zshrc

# machine-local below: PATH entries, tool installer blocks, one-off aliases
export PATH="$PATH:$HOME/.lmstudio/bin"
```

Because installers always *append*, whatever they add lands after the sourced config and
still applies. Drift collects in the stub instead of diverging from the repo copy.

The target only creates the stub when `~/.zshrc` is missing, and otherwise checks that the
`source` line is there. An existing full `~/.zshrc` -- one that sources oh-my-zsh itself --
stops the target with instructions rather than being appended to, since sourcing oh-my-zsh
twice re-runs the prompt setup. Migrating is a one-time manual edit: keep the machine-local
lines, move anything worth having everywhere into this repo's `.zshrc`, and put the
`source` line above the rest.

### Git branch and worktree helpers

`gwbd [-f|-ff] <branch>...` deletes branches that are checked out in a worktree, which
plain `git branch -D` refuses to do -- it removes each branch's worktree first, then deletes
them all in one `git branch -D`. A worktree whose directory was deleted by hand is pruned.
The branch of the main worktree, and any worktree you are currently standing in, are never
touched.

Force comes in the same two levels `git worktree remove` uses: `-f` removes a worktree
holding uncommitted or untracked files, and `-ff` also overrides a lock. Claude Code locks
every worktree it opens for a session, so `-ff` is what a branch left behind by a finished
session needs.

Install guide: https://github.com/robbyrussell/oh-my-zsh

List of themes: https://github.com/robbyrussell/oh-my-zsh/wiki/themes

Plugin for highlighting command: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md#oh-my-zsh

## Agnoster theme

Font — JetBrains Mono (https://github.com/JetBrains/JetBrainsMono), installed by the
Brewfile, or on its own:

```sh
brew install --cask font-jetbrains-mono
```

Then pick it in iTerm: CMD+i -> Text -> Font.

Alternatives: Powerline fonts (https://github.com/powerline/fonts), of which
FiraMono (https://github.com/powerline/fonts/tree/master/FiraMono).

Gruvbox: https://github.com/morhetz/gruvbox

## iTerm 2 Preferences

### Set up theme

Gruvbox theme for iterm2 and others: https://github.com/morhetz/gruvbox-contrib

- Download preset from link above
- CMD+i -> Colors -> Import...
- Make sure to override the default profile on General tab

![](https://monosnap.com/file/TfT2Al997aNhU8YvCZMIjWoDq9CCgX.png)

### "Cmd-Left/Right doesn't work"

- CMD+i -> Keys tab with its sub-tab Key Mappings
- Click Presets...
- Choose Natural Text Editing
