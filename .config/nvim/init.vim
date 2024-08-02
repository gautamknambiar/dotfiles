set mouse=a
set number
set confirm
set showtabline=2
set fillchars+=vert:█,horiz:█,horizup:█,horizdown:█,vertleft:█,vertright:█
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set incsearch
set hlsearch
colorscheme blue
set undofile
set undodir=~/.config/nvim/undodir
set clipboard=unnamedplus
autocmd BufWritePost ~/.config/nvim/init.vim source ~/.config/nvim/init.vim
set backspace=indent,eol,start
xnoremap <BS> "_c
filetype indent plugin on
syntax on

inoremap Ï <Esc>:nohlsearch<CR>i
vnoremap Ï <Esc>:nohlsearch<CR>i
nnoremap Ï <Esc>:nohlsearch<CR>

vnoremap ç "+y<Esc>i

nnoremap √ "+p<Esc>i
inoremap √ <C-o>"+p
vnoremap √ "+p<Esc>i

vnoremap ≈ "+d<Esc>i

vnoremap ∂ "_d<Esc>i

nnoremap ƒ ?
inoremap ƒ <Esc>?
vnoremap <silent> ƒ y/\V<C-R>=escape(@",'/\')<CR><CR>i

nnoremap º <Esc>:Lexplore<CR>:vertical resize 25<CR>

nnoremap “ <Esc>:vsplit<CR>

nnoremap ® <Esc>:so ~/.config/nvim/init.vim<CR>

nnoremap ß <Esc>:w<CR>
inoremap ß <Esc>:w<CR>i
vnoremap ß <Esc>:w<CR>

nnoremap œ <Esc>:q<CR>
inoremap œ <Esc>:q<CR>
vnoremap œ <Esc>:q<CR>

nnoremap ‘ <Esc>:tabnew<CR>

let g:netrw_browse_split = 4
let g:netrw_altv = 1

if exists("+showtabline")
    function! MyTabLine()
        let s = ''
        let wn = ''
        let t = tabpagenr()
        let i = 1
        while i <= tabpagenr('$')
            let buflist = tabpagebuflist(i)
            let winnr = tabpagewinnr(i)
            let s .= '%' . i . 'T'
            let s .= (i == t ? '%1*' : '%2*')
            let s .= ' '
            let wn = tabpagewinnr(i,'$')

            let s .= '%#TabNum#'
            let s .= i
            " let s .= '%*'
            let s .= (i == t ? '%#TabLineSel#' : '%#TabLine#')
            let bufnr = buflist[winnr - 1]
            let file = bufname(bufnr)
            let buftype = getbufvar(bufnr, 'buftype')
            if buftype == 'nofile'
                if file =~ '\/.'
                    let file = substitute(file, '.*\/\ze.', '', '')
                endif
            else
                let file = fnamemodify(file, ':p:t')
            endif
            if file == ''
                let file = '[No Name]'
            endif
            let s .= ' ' . file . ' '
            let i = i + 1
        endwhile
        let s .= '%T%#TabLineFill#%='
        let s .= (tabpagenr('$') > 1 ? '%999XX' : 'X')
        return s
    endfunction
    set stal=2
    set tabline=%!MyTabLine()
    set showtabline=1
    highlight link TabNum Special
endif
