CLAUDE_DIR ?= $(HOME)/.claude

.PHONY: bootstrap install install-vim install-claude install-git install-brew check-brew test test-claude

# Fresh machine: packages first, then the configs that depend on them.
bootstrap: install-brew install

install: install-vim install-claude install-git

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

# Statusline + /my-usage. Leaves ~/.claude/statusline.conf alone (opt-in, see
# claude/statusline.conf.example) and patches only the statusLine key in settings.json.
install-claude:
	@mkdir -p $(CLAUDE_DIR)/commands
	@cp ./claude/statusline.sh $(CLAUDE_DIR)/statusline.sh
	@cp ./claude/usage-refresh.sh $(CLAUDE_DIR)/usage-refresh.sh
	@chmod +x $(CLAUDE_DIR)/statusline.sh $(CLAUDE_DIR)/usage-refresh.sh
	@cp ./claude/commands/my-usage.md $(CLAUDE_DIR)/commands/my-usage.md
	@sh ./claude/patch-settings.sh $(CLAUDE_DIR)/settings.json
