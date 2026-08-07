CLAUDE_DIR ?= $(HOME)/.claude

.PHONY: install install-vim install-claude install-git test test-claude

install: install-vim install-claude install-git

test: test-claude

test-claude:
	@sh ./claude/statusline_test.sh

# Only the global ignore file. ~/.gitconfig is deliberately left alone: identity,
# gpg and lfs settings live there and exist only on the machine.
install-git:
	@cp ./.gitignore_global ~/.gitignore_global
	@git config --global core.excludesfile ~/.gitignore_global

install-vim:
	@rm -f ~/.vimrc
	@rm -rf ~/.vim
	@cp ./.vimrc ~/.vimrc
	@cp -R ./.vim ~/.vim

# Statusline + /my-usage. Leaves ~/.claude/statusline.conf alone (opt-in, see
# claude/statusline.conf.example) and patches only the statusLine key in settings.json.
install-claude:
	@mkdir -p $(CLAUDE_DIR)/commands
	@cp ./claude/statusline.sh $(CLAUDE_DIR)/statusline.sh
	@cp ./claude/usage-refresh.sh $(CLAUDE_DIR)/usage-refresh.sh
	@chmod +x $(CLAUDE_DIR)/statusline.sh $(CLAUDE_DIR)/usage-refresh.sh
	@cp ./claude/commands/my-usage.md $(CLAUDE_DIR)/commands/my-usage.md
	@sh ./claude/patch-settings.sh $(CLAUDE_DIR)/settings.json
