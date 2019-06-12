if has('python3')
  silent! python3 1
endif

scriptencoding utf-8
set encoding=utf-8

set hidden
set nocompatible                  " don't need to be compatible with old vim
filetype off                      " required

call plug#begin('~/.vim/bundle')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'qpkorr/vim-bufkill'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'shumphrey/fugitive-gitlab.vim'
Plug 'sheerun/vim-polyglot'
Plug 'scrooloose/nerdtree'
Plug 'airblade/vim-gitgutter'
Plug 'ntpeters/vim-better-whitespace'
Plug 'scrooloose/nerdcommenter'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'editorconfig/editorconfig-vim'
Plug 'morhetz/gruvbox'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
Plug 'tmhedberg/matchit'
Plug 'romainl/vim-qf'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'mileszs/ack.vim'
Plug 'posva/vim-vue'
Plug 'othree/html5.vim'
Plug 'pangloss/vim-javascript'
Plug 'isRuslan/vim-es6'
Plug 'digitaltoad/vim-pug'
Plug 'junegunn/fzf.vim', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'bogado/file-line'
Plug 'neomake/neomake'
Plug 'tpope/vim-projectionist'
Plug 'AndrewRadev/switch.vim'
Plug 'janko-m/vim-test'

call plug#end()

let g:airline_theme='base16'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#show_tabs = 1
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#show_close_button = 0

let g:neomake_ruby_enabled_makers = ['mri']

let g:neomake_ruby_enabled_makers = ['mri']
let g:neomake_ruby_rubocop_exe = 'bundle'
let g:neomake_ruby_rubocop_args = ['exec', 'rubocop']

" autocmd! BufWritePost * Neomake
" autocmd! BufReadPost * Neomake

syntax on             " show syntax highlig
filetype on           " Enable filetype detection
filetype indent on    " Enable filetype-specific indenting
filetype plugin on    " Enable filetype-specific plugins

autocmd BufNewFile,BufRead *.vue set filetype=vue.html.javascript
autocmd BufNewFile,BufRead *.html.erb set filetype=html.eruby
autocmd BufNewFile,BufRead *.es6 set filetype=javascript
autocmd BufNewFile,BufRead *.axlsx set filetype=ruby

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

" fzf configuration
set rtp+=/usr/local/opt/fzf

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
set noswapfile                    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set nobackup
set nowritebackup

set wildmenu                      " enable bash style tab completion
set pastetoggle=<F2>
set autoread                      " Automatically read files when they were changed on the filesystem
set re=1                          " Use new regex engine

" status line layout
set stl=%t\ %m\ %r\ \ %y\ \ %{fugitive#statusline()}\ \ %l/%L[%p%%]\ \ Col:\ %c\ \ Buf:\ #%n\

" set dark background and color scheme
set background=dark
colorscheme gruvbox

" Enable swapping background quickly
" http://tilvim.com/2013/07/31/swapping-bg.html
map <Leader>bg :let &background = ( &background == "dark"? "light" : "dark")<CR>

" Replace hash rockets with Ruby 1.9-style hashes
let @h = ":s/:\\([^=,'\"]*\\) =>/\\1:/g\<C-m>"

let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'

let g:NERDTreeNodeDelimiter = "\u00a0"
let NERDTreeMinimalUI = 1
let NERDTreeShowHidden = 1

if has('gui_running')
  set guifont=Menlo:h12 " set fonts for gui vim
  set guioptions=egmrt  " hide the gui menubar
endif

" The Silver Searcher
if executable('ag')
  let g:ackprg = 'ag --vimgrep --nogroup --nocolor'
endif

let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

let g:neoterm_position = 'horizontal'

" bind K to grep word under cursor
nnoremap K :Ack! "\b<C-R><C-W>\b"<CR>:cw<CR>

" find in project
nnoremap <Leader>\ :Ack!<SPACE>

" Strip whitespaces on save
autocmd BufWritePre * StripWhitespace

" Run a given vim command on the results of alt from a given path.
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
nnoremap <Leader>. :w<CR>:call AltCommand(expand('%'), ':tabe')<CR>

" Use Alt-j/k to move lines up and down
nnoremap ∆ :m .+1<CR>==
nnoremap ˚ :m .-2<CR>==
inoremap ∆ <Esc>:m .+1<CR>==gi
inoremap ˚ <Esc>:m .-2<CR>==gi
vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv

nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

map <Leader>k :Gstatus<CR>7+
map <Leader>K :Gpush<CR>

map <C-\> :NERDTreeToggle<CR>
map <C-n> :NERDTreeFind<CR>

" Clear highlighting on double escape in normal mode
nnoremap <silent> <Esc><Esc> :let @/=""<CR>

map <Leader>m :Vexplore db/migrate<CR>

nnoremap S "_diwP
vnoremap S "_dP

" Buffers related mappings
nnoremap <Leader>bb :buffers<CR>:buffer<Space>
nnoremap <Leader>bd :bd<CR>
nnoremap <Leader>q :BD<CR>

nnoremap “ :bp<CR>
nnoremap ‘ :bn<CR>

" Use Alt-[ to navigate to previos tab
" nnoremap ” :tabp<CR>
" Use Alt-] to navigate to next tab
" nnoremap ’ :tabn<CR>

nnoremap gG :call GotoFirstEffectiveLine()<CR>

nmap <Leader>r :Neomake rubocop<CR>

noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>
nnoremap Q <NOP>
nnoremap q: <NOP>
inoremap jk <ESC>
nmap :q :<ESC>

:command! Q q
:command! W w
nnoremap ; :

" --column: Show column number
" --line-number: Show line number
" --no-heading: Do not show file headings in results
" --fixed-strings: Search term as a literal string
" --ignore-case: Case insensitive search
" --no-ignore: Do not respect .gitignore, etc...
" --hidden: Search hidden files and folders
" --follow: Follow symlinks
" --glob: Additional conditions for search (in this case ignore everything in the .git/ folder)
" --color: Search color options
command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>), 1, <bang>0)

if has('nvim')
  let test#strategy = 'neovim'
endif

set grepprg=rg\ --vimgrep

let g:test#preserve_screen = 1
let test#ruby#bundle_exec = 0
if filereadable('bin/spring')
  let test#ruby#rspec#executable = 'bundle exec spring rspec'
else
  let test#ruby#rspec#executable = 'bundle exec rspec'
endif

nmap <Leader>s :w<CR>:TestNearest<CR>
nmap <Leader>t :w<CR>:TestFile<CR>
nmap <Leader>l :w<CR>:TestLast<CR>

" convert `var_name = 'value'` to `let(:var_name) { 'value' }`
nmap <Leader>ivl 0df@==ilet(<ESC>lxi:<ESC>ea)<ESC>wdwDA{<SPACE><ESC>p
nmap <Leader>vl 0==ilet(<ESC>lxi:<ESC>ea)<ESC>wdwDA{<SPACE><ESC>p
nmap <Leader>cl :'<,'>s/;//g<CR>^DAconsole.log(<ESC>pA;<ESC>F(l

nmap <Leader>py <Esc>:w<CR>:!clear;python3 %<CR>

nnoremap <silent> gs :Switch<cr>

noremap <C-p> :FZF<CR>

set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz
nnoremap ж :
