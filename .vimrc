scriptencoding utf-8
set encoding=utf-8

execute pathogen#infect()

syntax on                         " show syntax highlig

filetype plugin indent on
set autoindent                    " set auto indent
set ts=2                          " set indent to 2 spaces
set shiftwidth=2
set expandtab                     " use spaces, not tab characters
set nocompatible                  " don't need to be compatible with old vim
set relativenumber                " show relative line numbers
set showmatch                     " show bracket matches
set ignorecase                    " ignore case in search
set hlsearch                      " highlight all search matches
set cursorline                    " highlight current line
set smartcase                     " pay attention to case when caps are used
set incsearch                     " show search results as I type
set mouse=a                       " enable mouse support
set ttimeoutlen=100               " decrease timeout for faster insert with 'O'
set vb                            " enable visual bell (disable audio bell)
set ruler                         " show row and column in footer
set scrolloff=2                   " minimum lines above/below cursor
set laststatus=2                  " always show status bar
set list listchars=tab:»·,trail:· " show extra space characters
set nofoldenable                  " disable code folding
set clipboard=unnamed             " use the system clipboard
set wildmenu                      " enable bash style tab completion
set pastetoggle=<F2>              " toggle paste mode using <F2> key

" set dark background and color scheme
set background=dark
colorscheme solarized

if has('gui_running')
  set guifont=Menlo:h12    " set fonts for gui vim
  set transparency=5        " set transparent window
  set guioptions=egmrt  " hide the gui menubar
endif

let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
