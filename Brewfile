# Tools the configs in this repo assume. Install with `make install-brew`,
# see what is missing with `make check-brew`.
#
# Intentionally unpinned, and intentionally no .tool-versions here: asdf owns the
# language runtimes per project, and those versions move too fast to track in dotfiles.
# Scope is "something in this repo breaks without it" — general dev tooling stays out.

brew "git"
brew "git-lfs"   # ~/.gitconfig declares the lfs filters with required = true
brew "gnupg"     # .gitconfig gpg.program
brew "jq"        # claude/statusline.sh, patch-settings.sh, statusline_test.sh
brew "vim"       # .vimrc, and the `vi` alias in .zshrc
brew "zsh"
brew "ripgrep"   # the rg in FZF_DEFAULT_COMMAND
brew "fzf"
brew "asdf"      # runtime versions stay in each project's own .tool-versions
brew "coreutils"

# The powerline font the agnoster theme and iTerm profile expect.
# https://github.com/JetBrains/JetBrainsMono
# If JetBrainsMono-*.ttf were already dropped into ~/Library/Fonts by hand, brew will
# refuse to link over them. Clear the hand-installed copies first, or adopt them:
#   brew install --cask --adopt font-jetbrains-mono
cask "font-jetbrains-mono"

# GUI apps this repo configures. Left commented because they are already installed by
# hand on this machine, and brew refuses to take over a non-brew app — uncommenting
# would make `make install-brew` fail here.
#
# On a fresh machine, uncomment. To hand an existing manual install over to brew:
#   brew install --cask --adopt iterm2
#
# cask "iterm2"               # README: gruvbox preset, Natural Text Editing
# cask "vlc"                  # the vlc alias in .zshrc
#
# Not here on purpose: oh-my-zsh and zsh-syntax-highlighting (installed by their own
# scripts, see README), and the claude CLI (lives in ~/.local/bin).
