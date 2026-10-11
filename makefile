CLAUDE_DIR ?= $(HOME)/.claude

# Without this a bare `make` would run whatever target happens to come first, which is
# bootstrap -- and bootstrap reaches for brew. Plain `make` stays the harmless one: it
# only lays down configs, and installing packages stays a deliberate `make bootstrap`.
.DEFAULT_GOAL := install

.PHONY: bootstrap install install-vim install-claude install-git install-zsh install-herdr install-iterm2 install-brew check-brew test test-claude

# Fresh machine: packages first, then the configs that depend on them.
bootstrap: install-brew install

install: install-vim install-claude install-git install-zsh install-herdr install-iterm2

test: test-claude

test-claude:
	@sh ./claude/statusline_test.sh

# --no-upgrade: install what is missing, never touch what is already there. Without it
# brew bundle treats "installed but outdated" as unsatisfied and upgrades it, which turns
# this into an unrelated system upgrade. Upgrading stays a deliberate `brew upgrade`.
install-brew:
	@command -v brew >/dev/null 2>&1 || { echo "brew not found: https://brew.sh"; exit 1; }
	@brew bundle install --no-upgrade --file=./Brewfile

# Non-destructive: lists what the Brewfile wants that is not installed yet.
check-brew:
	@command -v brew >/dev/null 2>&1 || { echo "brew not found: https://brew.sh"; exit 1; }
	@brew bundle check --no-upgrade --file=./Brewfile --verbose

# ~/.gitconfig is never overwritten: identity, gpg and lfs settings live there and exist
# only on the machine. Instead this repo's .gitconfig is pulled in via include.path, so
# the settings here actually apply while the machine-local ones stay put. The include is
# appended, so values here win over anything set earlier in ~/.gitconfig.
install-git:
	@cp ./.gitignore_global ~/.gitignore_global
	@git config --global core.excludesfile ~/.gitignore_global
	@git config --global --get-all include.path 2>/dev/null | grep -qxF "$(CURDIR)/.gitconfig" \
		|| git config --global --add include.path "$(CURDIR)/.gitconfig"

# ~/.vim is deliberately left alone: vim-plug installs itself to ~/.vim/autoload and its
# plugins to ~/.vim/bundle, and the old `rm -rf ~/.vim` deleted both on every run. .vimrc
# bootstraps plug.vim by itself when it is missing.
install-vim:
	@cp ./.vimrc ~/.vimrc

# ~/.zshrc is never overwritten, for the same reason ~/.gitconfig is not: tool installers
# (asdf, bun, LM Studio, ...) append their own blocks to it, and those are machine-local by
# nature. Instead ~/.zshrc becomes a stub that sources this repo's .zshrc, and since
# installers always append, whatever they add lands after it and still applies.
#
# A ~/.zshrc that is still a full config would source oh-my-zsh twice and re-run the prompt
# setup, so that case stops here with instructions rather than quietly breaking the shell.
install-zsh:
	@if [ ! -e $(HOME)/.zshrc ]; then \
		printf 'source %s/.zshrc\n' "$(CURDIR)" > $(HOME)/.zshrc; \
		echo "created ~/.zshrc sourcing $(CURDIR)/.zshrc"; \
	elif ! grep -qF '$(CURDIR)/.zshrc' $(HOME)/.zshrc; then \
		echo "~/.zshrc exists and does not source $(CURDIR)/.zshrc."; \
		echo "Keep only the machine-local lines in it -- PATH entries and blocks written by"; \
		echo "tool installers -- and put this line above them:"; \
		echo ""; \
		echo "    source $(CURDIR)/.zshrc"; \
		echo ""; \
		echo "Anything in ~/.zshrc worth having on every machine belongs in this repo's"; \
		echo ".zshrc instead. See the ZSH section of README.md."; \
		exit 1; \
	fi

# herdr keeps everything in one config.toml -- keybindings, theme, sidebar layout -- so
# like .vimrc this file is overwritten wholesale: the repo's copy is the source of truth.
# If you change settings from inside herdr, copy the file back into this repo. The reload
# at the end is best-effort: with no herdr installed or no server running there is simply
# nothing to reload.
install-herdr:
	@mkdir -p $(HOME)/.config/herdr
	@cp ./herdr/config.toml $(HOME)/.config/herdr/config.toml
	@herdr server reload-config >/dev/null 2>&1 || true

# iTerm2 dynamic profile: iTerm2 watches the DynamicProfiles folder and hot-reloads it,
# so the profile appears (or updates) without a restart. Editing the profile in iTerm2's
# GUI does NOT write back to the file -- edit iterm2/Herdr.json instead.
install-iterm2:
	@mkdir -p "$(HOME)/Library/Application Support/iTerm2/DynamicProfiles"
	@cp ./iterm2/Herdr.json "$(HOME)/Library/Application Support/iTerm2/DynamicProfiles/Herdr.json"

# Statusline + /my-usage + standing preferences. Leaves ~/.claude/statusline.conf alone
# (opt-in, see claude/statusline.conf.example) and patches only the statusLine key in
# settings.json.
#
# Preferences install as a user-level rule, not as ~/.claude/CLAUDE.md: rules in
# ~/.claude/rules/*.md load unconditionally in every project, exactly like the user
# CLAUDE.md does, so this repo can own its file outright while ~/.claude/CLAUDE.md stays
# free for hand-written notes that no `make` will ever clobber. dotfiles.md itself IS
# overwritten wholesale -- edit it in this repo, not in ~/.claude.
install-claude:
	@mkdir -p $(CLAUDE_DIR)/commands $(CLAUDE_DIR)/rules
	@cp ./claude/rules/dotfiles.md $(CLAUDE_DIR)/rules/dotfiles.md
	@cp ./claude/statusline.sh $(CLAUDE_DIR)/statusline.sh
	@cp ./claude/usage-refresh.sh $(CLAUDE_DIR)/usage-refresh.sh
	@chmod +x $(CLAUDE_DIR)/statusline.sh $(CLAUDE_DIR)/usage-refresh.sh
	@cp ./claude/commands/my-usage.md $(CLAUDE_DIR)/commands/my-usage.md
	@sh ./claude/patch-settings.sh $(CLAUDE_DIR)/settings.json
