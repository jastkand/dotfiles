scriptencoding utf-8
set encoding=utf-8

execute pathogen#infect()

set nocompatible                  " don't need to be compatible with old vim
filetype off                      " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'     " let Vundle manage Vundle, required
Plugin 'tpope/vim-fugitive'       " plugin on GitHub repo
Plugin 'thoughtbot/vim-rspec'
Plugin 'scrooloose/nerdtree'
Plugin 'airblade/vim-gitgutter'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'scrooloose/nerdcommenter'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'morhetz/gruvbox'
Plugin 'kien/ctrlp.vim'
Plugin 'scrooloose/syntastic'
Plugin 'slim-template/vim-slim'
Plugin 'tpope/vim-bundler'
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-surround'
Plugin 'vim-ruby/vim-ruby'
Plugin 'jiangmiao/auto-pairs'
Plugin 'kassio/neoterm'
Plugin 'romainl/vim-qf'
Plugin 'AndrewRadev/splitjoin.vim'
Plugin 'mileszs/ack.vim'
Plugin 'othree/yajs.vim'
Plugin 'othree/es.next.syntax.vim'
Plugin 'kchmck/vim-coffee-script'

" All of your Plugins must be added before the following line
call vundle#end()            " required

syntax on             " show syntax highlig
filetype on           " Enable filetype detection
filetype indent on    " Enable filetype-specific indenting
filetype plugin on    " Enable filetype-specific plugins

" consider es6 files as javascript ones
au BufNewFile,BufRead *.es6 set filetype=javascript

autocmd FileType ruby compiler ruby

" Navigates to the first non-comment line. Thanks to https://github.com/vim-scripts/FirstEffectiveLine.vim
function! GotoFirstEffectiveLine()
  let l:c = 0
  while l:c<line("$") && (
        \ getline(l:c) =~ '^\s*$'
        \ || synIDattr(synID(l:c, 1, 0), "name") =~ ".*Comment.*"
        \ || synIDattr(synID(l:c, 1, 0), "name") =~ ".*PreProc$"
        \)
    let l:c = l:c+1
  endwhile
  exe "normal ".l:c."Gz\<CR>"
endfunction

let mapleader=" "

" Indent based on previous line
set autoindent

" Set tab width, tab width on deletion and use spaces instead of tabs
set ts=2 sts=2 sw=2 expandtab

" Make the backspace key act like it does in any editor (remove characters, indentation and end of lines)
set backspace=indent,eol,start
" set backspace=2

" Highlight 100, 120 position in file
set colorcolumn=101,121

" show line number with relative line numbers at the same time
set relativenumber
set number

" show bracket matches
set showmatch

" Enable case insensitivity, but enable case insensitivity if there is at least one upper letter
set ignorecase
set smartcase

" Highlight search results
set hlsearch

" Highlight current line
set cursorline

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

" No backup and swap files
set nobackup
set nowritebackup
set noswapfile                    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287

set wildmenu                      " enable bash style tab completion
set pastetoggle=<F2>
set autoread                      " Automatically read files when they were changed on the filesystem
set re=1                          " Use new regex engine

" status line layout
set stl=%t\ %m\ %r\ \ %y\ \ %{fugitive#statusline()}\ \ %l/%L[%p%%]\ \ Col:\ %c\ \ Buf:\ #%n\

" set dark background and color scheme
set background=dark
colorscheme gruvbox

let g:NERDSpaceDelims = 1
let NERDTreeMinimalUI = 1
let NERDTreeShowHidden = 1

if has('gui_running')
  set guifont=Menlo:h12 " set fonts for gui vim
  set guioptions=egmrt  " hide the gui menubar
endif

" The Silver Searcher
if executable('ag')
  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0

  let g:ackprg = 'ag --vimgrep --nogroup --nocolor'
endif

let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" bind K to grep word under cursor
nnoremap K :Ack! "\b<C-R><C-W>\b"<CR>:cw<CR>

" bind \ (backward slash) to grep shortcut
nnoremap \ :Ack!<SPACE>

" Strip whitespaces on save
autocmd BufWritePre * StripWhitespace

" Run a given vim command on the results of alt from a given path.
" See usage below.
function! AltCommand(path, vim_command)
  let l:alternate = system("alt " . a:path)
  if empty(l:alternate)
    echo "No alternate file for " . a:path . " exists!"
  else
    exec a:vim_command . " " . l:alternate
  endif
endfunction

command! MakeTags !ctags -R --languages=ruby --exclude=.git --exclude=log . $(bundle list --paths)

" Find the alternate file for the current path and open it
nnoremap <leader>. :w<CR>:call AltCommand(expand('%'), ':tabe')<CR>

let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_reuse_window = 'NERD_tree_1'

let g:rspec_runner = "os_x_iterm2"
let g:rspec_command = "!bundle exec spring rspec {spec}"

if has("nvim")
  let g:rspec_command = "tabnew | term bundle exec spring rspec {spec}"
endif

let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

let g:neoterm_position = 'horizontal'

nnoremap ∆ :m .+1<CR>==
nnoremap ˚ :m .-2<CR>==
inoremap ∆ <Esc>:m .+1<CR>==gi
inoremap ˚ <Esc>:m .-2<CR>==gi
vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv

map <Leader>t :w<CR>:call RunCurrentSpecFile()<CR>
map <Leader>s :w<CR>:call RunNearestSpec()<CR>
map <Leader>l :w<CR>:call RunLastSpec()<CR>

map <Leader>k :Gstatus<CR>7+
map <Leader>K :Gpush<CR>

map <C-\> :NERDTreeToggle<CR>
map <C-n> :NERDTreeFind<CR>

" Use Alt-[ to navigate to previos tab
nnoremap “ :tabprevious<CR>
" Use Alt-] to navigate to next tab
nnoremap ‘ :tabnext<CR>

" Clear highlighting on double escape in normal mode
nnoremap <silent> <Esc><Esc> :let @/=""<CR>

map <Leader>m :Vexplore db/migrate<CR>

" quickfix open in new tab shortcut
nnoremap <c-x>t <c-w><cr><c-w>T

nnoremap S "_diwP
vnoremap S "_dP

" navigate to previos buffer
nnoremap <Leader>g :e#<CR>

nnoremap gG :call GotoFirstEffectiveLine()<CR>
