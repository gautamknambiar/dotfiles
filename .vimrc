autocmd BufWritePost ~/.vimrc source ~/.vimrc

" Enable mouse support in all modes
set mouse=a

" Enable line numbers
set number

" Use the system clipboard
set clipboard=unnamedplus

" Enable undo persistence
set undofile
set undodir=~/.vim/undodir

" Improve searching
set incsearch
set hlsearch

" Set intuitive backspace behavior
set backspace=indent,eol,start

" Ensure spaces are used for indentation
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Disable swap files
set noswapfile

" Enable soft wrapping
set wrap

"blue        default     desert      evening     industry    lunaperche  murphy      peachpuff   ron         slate       zellner
"darkblue    delek       elflord     habamax     koehler     morning     pablo       quiet       shine       torte
"desert

" Set a color scheme 
colorscheme default

" Enable file type detection and syntax highlighting
filetype plugin indent on
syntax on

execute "set <M-c>=ç"
execute "set <M-v>=√"
execute "set <M-x>=≈"
execute "set <M-d>=∂"
execute "set <M-f>=ƒ"
execute "set <M-F>=Ï"

inoremap <M-F> <Esc>:nohlsearch<CR>i
nnoremap <M-F> <Esc>:nohlsearch<CR>i
vnoremap <M-F> <Esc>:nohlsearch<CR>i

" Map Alt+C to Copy (Yank) to system clipboard and return to insert mode
vnoremap <M-c> "+y<Esc>i

" Map Alt+V to Paste from system clipboard and return to insert mode
nnoremap <M-v> "+p<Esc>i
inoremap <M-v> <C-o>"+p
vnoremap <M-v> "+p<Esc>i

" Map Alt+X to Cut (Delete and Copy) to system clipboard and return to insert mode
vnoremap <M-x> "+d<Esc>i

" Map Alt+D to Delete without copying to any register (black hole) and return to insert mode
vnoremap <M-d> "_d<Esc>i

" Map Alt+D to Delete without copying to any register (black hole) and return to insert mode
nnoremap <M-f> "<Esc>?
inoremap <M-f> "<Esc>?
vnoremap <silent> <M-f> y/\V<C-R>=escape(@",'/\')<CR><CR>i

" Map Ctrl+S to Save
nnoremap <C-s> :w<CR>

" Map Ctrl+Q to Quit
nnoremap <C-q> :q<CR>
