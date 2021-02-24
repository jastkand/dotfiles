install-vim:
	@rm -f ~/.vimrc
	@rm -rf ~/.vim
	@cp ./.vimrc ~/.vimrc
	@cp -R ./.vim ~/.vim
