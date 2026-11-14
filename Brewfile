# Tools the configs in this repo assume. Install with `make install-brew`,
# see what is missing with `make check-brew`.
#
# Intentionally unpinned, and intentionally no .tool-versions here: asdf owns the
# language runtimes per project, and those versions move too fast to track in dotfiles.
# Scope is "something in this repo breaks without it" — general dev tooling stays out.

brew "git"
brew "git-lfs"   # ~/.gitconfig declares the lfs filters with required = true
brew "gnupg"     # .gitconfig gpg.program
brew "herdr"     # herdr/config.toml, and the iterm2/Herdr.json profile's key chords
brew "tuios"     # the iterm2/Tuios.json profile
brew "jq"        # claude/statusline.sh, patch-settings.sh, statusline_test.sh
brew "vim"       # .vimrc, and the `vi` alias in .zshrc
brew "zsh"
brew "ripgrep"   # the rg in FZF_DEFAULT_COMMAND
brew "fzf"
brew "asdf"      # runtime versions stay in each project's own .tool-versions
brew "coreutils"

# The font the agnoster theme and the iTerm profiles expect: "JetBrainsMonoNL Nerd Font
# Mono" (PostScript JetBrainsMonoNLNFM-*). JetBrains Mono patched with Nerd Font icons,
# which tuios draws in its sidebar and dock; NL = no ligatures, Mono = icons kept to one
# cell wide. https://www.nerdfonts.com/
# If the *NerdFont*.ttf files were already dropped into ~/Library/Fonts by hand (the
# nerdfonts.com download), brew will refuse to link over them. Clear the hand-installed
# copies first, or adopt them:
#   brew install --cask --adopt font-jetbrains-mono-nerd-font
cask "font-jetbrains-mono-nerd-font"

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
