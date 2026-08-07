## Install

```sh
make            # vim + claude + git
make install-claude
make install-git    # ~/.gitignore_global only; ~/.gitconfig is left alone,
                    # since identity, gpg and lfs settings are machine-local
make test
```

## Claude Code

```sh
make install-claude
```

Copies into `~/.claude/`:

- `statusline.sh` — `<model> (<effort>) | <dir> | <branch> | <ticket> | <usage>`
- `usage-refresh.sh` — background helper caching `/usage` into `~/.claude/usage-cache.json`
- `commands/my-usage.md` — `/my-usage`, reads that cache and reports subscription limits

`settings.json` is not overwritten: only its `statusLine` key is patched in with `jq`, so
`model`, `theme`, `effortLevel` and `enabledPlugins` stay machine-local. Requires `jq`.

### Ticket extension (opt-in)

The ticket segment renders nothing until configured, so the statusline is safe to install
anywhere. To turn it on, copy `claude/statusline.conf.example` to either scope:

| Path | Scope |
| --- | --- |
| `<repo>/.claude/statusline.conf` | per project — wins over the machine default |
| `~/.claude/statusline.conf` | machine-wide fallback |

```sh
TICKET_PREFIX=PROJ
TICKET_URL=https://linear.app/your-workspace/issue/{ticket}
```

The prefix is matched case-insensitively against the session name first, then the git branch —
`feature/proj-1234-add-thing` becomes a clickable `PROJ-1234`. Drop `TICKET_URL` to show the bare
id. `CLAUDE_STATUSLINE_TICKET_PREFIX` / `CLAUDE_STATUSLINE_TICKET_URL` override both files.
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

Install guide: https://github.com/robbyrussell/oh-my-zsh

List of themes: https://github.com/robbyrussell/oh-my-zsh/wiki/themes

Plugin for highlighting command: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md#oh-my-zsh

## Agnoster theme

Powerline fonts repo: https://github.com/powerline/fonts

JetBrainsMono: https://github.com/JetBrains/JetBrainsMono

FiraMono Powerline font: https://github.com/powerline/fonts/tree/master/FiraMono

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
