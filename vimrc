
set nocompatible
if has("multi_byte")
    if &termencoding == ""
        let &termencoding = &encoding
    endif
    set encoding=utf-8
    setglobal fileencoding=utf-8
    set fileencodings=ucs-bom,utf-8,latin1
endif

let g:is_ssh = ($SSH_TTY != "")

" Bundles and their settings are specified externally.
source $HOME/.vim/rc/plugins

" Preferences {{{
    syntax on

    " Editor looks {{{
        " Disable matchit, I find it distracting
        let loaded_matchparen = 1

        set background=dark
        let g:rehash256 = 1
        colorscheme molokai

        set number                   " Line numbers
        set showcmd                  " Show command issued
        set fillchars=vert:¦
        set list
        set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
        set textwidth=88
        set cursorline               " Line highlight

        set synmaxcol=1500

        " Change color of status line when unfocused (in tmux)
        au FocusLost * hi StatusLine ctermfg=235 ctermbg=240
        au FocusGained * hi StatusLine ctermfg=238 ctermbg=253
    " }}}

    " Behavior {{{
        set autoread                 " Auto-update a file that's been edited externally
        set backspace=indent,eol,start
        set fileformats+=mac
        set hidden                   " Allow buffer switching without saving
        set lazyredraw               " Don't update screen while running macros
        set noeol
        set nospell                  " No spell check, please
        set nrformats-=octal
        set shortmess+=filmnrxoOtTs
        set ttyfast                  " Faster terminal
        set visualbell               " No sounds!

        set iskeyword-=.             " Regard . as a word boundary
        set iskeyword-=_             " Regard _ as a word boundary
        set iskeyword-=#             " Regard # as a word boundary

        " Switch to current file directory
        autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" | lcd %:p:h | endif

        if !has('nvim')
            if has('clipboard')
                if has('unnamedplus')  " When possible use + register for copy-paste
                    set clipboard=unnamed,unnamedplus
                else " On mac and Windows, use * register for copy-paste
                    set clipboard=unnamed
                endif
            endif
        endif

        " Restore cursor to file position in previous editing session
        function! ResCur()
            if line("'\"") <= line("$")
                silent! normal! g`"
                return 1
            endif
        endfunction

        augroup resCur
            autocmd!
            autocmd BufWinEnter * call ResCur()
        augroup END

        " Instead of reverting the cursor to the last position in the buffer, we
        " set it to the first line when editing a git commit message
        au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
    " }}}

    " StatusBar {{{
        set ruler                                      " Show line/col no in statusline
        set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)

        if has('statusline')
            set laststatus=2
            set statusline=%t                              " tail of the filename
            set statusline+=%w%h%m%r                       " Options
            set statusline+=%=                             " left/right separator
            set statusline+=\ %{fugitive#statusline()}     " Git Hotness
            set statusline+=<\ %y                           " filetype
            set statusline+=\ %c                             " cursor column
            set statusline+=\ %l/%L                        " cursor line/total lines
            set statusline+=\ \:%P                         " percent through file
        endif
    " }}}

    " Movement & search {{{
        set nostartofline
        set sidescrolloff=5
        set incsearch            " find as you type
        set hlsearch             " Highlight search terms
        set ignorecase           " case insensitive search
        set smartcase            " case sensitive when uc present
        set gdefault             " global flag for substitute by default

        if executable('ag')
            let g:ackprg = 'ag --nogroup --nocolor --column'
            set grepprg=ag\ --nogroup\ --nocolor
        elseif executable('ack-grep')
            let g:ackprg = "ack-grep -H --nocolor --nogroup --column"
        endif
    " }}}

    " Text formatting {{{
        set autoindent
        set expandtab
        set shiftround
        set shiftwidth=4 tabstop=4 softtabstop=4
        set nowrap
        " Backspace and cursor keys to wrap
        set whichwrap=b,s,h,l,<,>,[,]
        " see :h fo-table
        set formatoptions=qrn1lr

        function! <SID>StripTrailingWhitespaces()
            if &ft =~ 'vim'
                return
            endif
            let l = line(".")
            let c = col(".")
            %s/\s\+$//e
            call cursor(l, c)
        endfunction
        autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()
    " }}}

    " Folding {{{
        set foldlevel=1
        " Cleaner, readable fold headers
        set foldtext=MyFoldText()
        function! MyFoldText()
            let line = getline(v:foldstart)
            " Lines that have been folded
            let nl = v:foldend - v:foldstart + 1
            let indent = repeat(' ', indent(v:foldstart))
            let endcol = &colorcolumn ? &colorcolumn : &textwidth
            let startcol = &columns < endcol ? &columns-4 : endcol
            return indent . substitute(line,"^ *","",1)
        endfunction
    " }}}

    " Swap files, history & persistence {{{
        " No backup (that's what git is for!) and swapfiles are annoying
        set nobackup
        set nowritebackup
        set noswapfile
        if has('persistent_undo')
            set undodir=~/.vim/tmp/undo
            set undolevels=500
            set undoreload=500
        endif
        set history=5000

        " preserve buffer state (cursor location, folds, etc.)
        set viewdir=~/.vim/tmp/views
        set viewoptions=cursor,folds,unix,slash
        augroup persistence
            au!
            au BufWinLeave * if expand("%") != "" | silent! mkview | endif
            au BufWinEnter * if expand("%") != "" | silent! loadview | endif
        augroup END
    " }}}

    " Omnicomplete + wild settings {{{
        set tags=./tags,./../tags,./../../tags,./../../../tags,tags

        set complete-=i
        set completeopt=menu
        set wildmenu                    " Show menu instead of auto-complete
        set wildmode=list:longest,full  " command <Tab> completion: list
                                        " matches -> longest common -> then
                                        " all.
        set wildignore+=*.swp,*.log,.sass-cache,.codekit-cache,config.codekit
        set wildignore+=*.class,*.o,*.pyc,*.obj,*DS_Store*
    " }}}

    " Show buffer name in tmux window name
    set titlestring=%f%m
    set title

    " Automatically close the popup menu / preview window
    au InsertLeave * if pumvisible() == 0|silent! pclose|endif
    " For some reason vaxe's ftdetect isn't always on the ball
    au BufRead,BufNewFile *.hx set filetype=haxe
    " For emacs Caskfiles
    au BufRead,BufNewFile Cask set filetype=lisp
    " No cursorline in inactive buffers
    au VimEnter,WinEnter,BufWinEnter,FocusGained,CmdwinEnter * setlocal cursorline
    au WinLeave,FocusLost,CmdwinLeave * setlocal nocursorline
    " In a git commit message buffer revert the cursor to the first line
    au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
" }}}

" rcfiles
source $HOME/.vim/rc/keymaps
source $HOME/.vim/rc/util
" If one exists, this is where you'll want local settings
try
    source $HOME/.vimrc.local
catch
endtry

" vim:set fdl=0 fdm=marker:
