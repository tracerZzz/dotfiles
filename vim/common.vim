" ============================================================================
" Portable Vim Common Config (managed in ~/dotfiles)
" Usage: Append this single line to any machine's ~/.vimrc:
"   if filereadable(expand('~/dotfiles/vim/common.vim')) | source ~/dotfiles/vim/common.vim | endif
" ============================================================================
set nocompatible

" ============================================================================
" Plugins (managed by vim-plug)
" ============================================================================
if filereadable(expand('~/.vim/autoload/plug.vim'))
  call plug#begin('~/.vim/plugged')

  " File tree
  Plug 'preservim/nerdtree', { 'on': ['NERDTree', 'NERDTreeToggle', 'NERDTreeFocus', 'NERDTreeFind'] }

  " Colorscheme matching iTerm2 One Half Dark (includes vim-airline theme)
  Plug 'sonph/onehalf', { 'rtp': 'vim' }

  " Quick commenting: gcc (line), gc (visual selection)
  Plug 'tpope/vim-commentary'

  " Statusline
  Plug 'vim-airline/vim-airline'

  " Fuzzy finder
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  call plug#end()
endif

" ============================================================================
" Appearance & Theme
" ============================================================================
syntax on
set t_Co=256
if has('termguicolors')
  set termguicolors
endif
set background=dark

" Transparent background (inherit iTerm2 transparency & blur)
if has('autocmd')
  augroup TransparentBG
    autocmd!
    autocmd ColorScheme * highlight Normal ctermbg=NONE guibg=NONE
    autocmd ColorScheme * highlight NonText ctermbg=NONE guibg=NONE
    autocmd ColorScheme * highlight EndOfBuffer ctermbg=NONE guibg=NONE
    autocmd ColorScheme * highlight LineNr ctermbg=NONE guibg=NONE
    autocmd ColorScheme * highlight SignColumn ctermbg=NONE guibg=NONE
  augroup END
endif

silent! colorscheme onehalfdark

" Airline theme matching One Half Dark
let g:airline_theme = 'onehalfdark'

" ============================================================================
" Basic Editing Experience
" ============================================================================
set encoding=utf-8
set number                      " Show line numbers
set cursorline                  " Highlight current line
set tabstop=4                   " Visual width of a tab
set shiftwidth=4                " Indentation width for >> and <<
set softtabstop=4               " Tab key inserts 4 spaces
set expandtab                   " Convert tabs to spaces
set autoindent                  " Keep indentation on new lines
set backspace=indent,eol,start  " Normal backspace behavior
set autoread                    " Auto reload file when modified externally
set noswapfile                  " Avoid cluttering directories with .swp files
set mouse=a                     " Enable mouse scrolling/selection
set clipboard=unnamed           " Share clipboard with macOS system clipboard

" Search
set incsearch                   " Incremental search preview
set hlsearch                    " Highlight search matches
set ignorecase                  " Case-insensitive search...
set smartcase                   " ...unless query contains uppercase letters

" Restore cursor to last known position when reopening a file
if has('autocmd')
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line('$') | execute "normal! g'\"" | endif
endif

" ============================================================================
" Plugin Settings & Keymaps
" ============================================================================
" NERDTree
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

" FZF shortcuts
nnoremap <C-p> :Files<CR>
nnoremap <leader>f :Rg<CR>
nnoremap <leader>b :Buffers<CR>

" In-Vim Cheatsheet (run :hh or press \?, press q to close)
function! ShowVimCheatsheet()
  let l:dir = empty($DOTFILES_DIR) ? expand('$HOME/dotfiles') : $DOTFILES_DIR
  let l:sheet = l:dir . '/cheatsheets/vim.md'
  let l:renderer = l:dir . '/scripts/vh.py'
  if !filereadable(l:sheet)
    echo 'Vim cheatsheet not found: ' . l:sheet
    return
  endif
  botright vnew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap nonumber
  if filereadable(l:renderer) && executable('python3')
    let l:lines = systemlist('python3 ' . shellescape(l:renderer) . ' --plain ' . shellescape(l:sheet))
  else
    let l:lines = readfile(l:sheet)
  endif
  call setline(1, l:lines)
  setlocal nomodifiable readonly
  syntax match CheatTitle /^◆ .*/
  syntax match CheatSection /^▸ .*/
  syntax match CheatSub /^  \d\+\..*/
  syntax match CheatSep /^  [─═]\+/
  highlight link CheatTitle Title
  highlight link CheatSection Statement
  highlight link CheatSub Type
  highlight link CheatSep Comment
  nnoremap <buffer> <silent> q :close<CR>
endfunction
command! HH call ShowVimCheatsheet()
cnoreabbrev <expr> hh (getcmdtype() == ':' && getcmdline() == 'hh') ? 'HH' : 'hh'
nnoremap <leader>? :HH<CR>
