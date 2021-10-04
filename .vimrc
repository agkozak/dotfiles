" ~/.vimrc
"
" https://github.com/agkozak/dotfiles

" => Environment {{{1

silent function! CMDEXE() abort         " Returns true when the shell is cmd.exe
  return (&shell =~? 'cmd')
endfunction

silent function! WINDOWS() abort        " Returns true when the environment is
  return (has('win32') || has('win64')) " Windows (but not Cygwin/MSYS2/WSL)
endfunction

silent function! WSL2() abort
  if has('unix') && $VIM !~# 'iVim'
    return ($AGKDOT_SYSTEMINFO =~# 'microsoft' || system('uname -a'))
  endif
endfunction

" }}}1

" ALE Compatibility {{{

" Tests to see if ale can be used for syntax checking
function! ALECompatible() abort
  " ALE seems to slow down Vim startup on WSL2
  if WSL2()
    return 0
  endif
  return ((v:version >= 800 && has('job') && has('timers') && has('channel'))
        \ || has('nvim'))
endfunction

" }}}

" Options {{{1

" Options are arranged according to the sections in Vim's `:options` help
" menu.

" => 1 important {{{2

" Because of a bug, `set nocompatible' was necessary for a little while. See
" https://github.com/vim/vim/issues/3014
if v:version == 801 && has('patch37') && !has('patch55')
" vint: -ProhibitSetNoCompatible
  set nocompatible
endif

" }}}2

" => 2 moving around, searching and patterns {{{2

set incsearch               " Find-as-you-type search
set ignorecase              " Case insensitive search
set smartcase               " Case sensitive when uppercase present

" }}}2

" => 4 displaying text {{{2

set scrolloff=1             " Number of lines to keep above and below cursor
set display+=lastline       " Improve display of very long, wrapping lines
if &listchars ==# 'eol:$'   " Determine how `set list' displays white space
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
endif
set number                  " Line numbers on

" }}}2

" => 5 syntax, highlighting and spelling {{{2

set hlsearch                " Highlight search terms
set colorcolumn=80          " Vertical ruler at 80 characters

" }}}2

" => 6 multiple windows {{{2

set laststatus=2

set statusline=
set statusline+=[%n]                              " Buffer number
set statusline+=\ %<%.99f                         " Relative path to file
set statusline+=\ %h                              " Help buffer flag
set statusline+=%w                                " Preview window flag
set statusline+=%m                                " Modified flag
set statusline+=%r                                " Readonly flag
set statusline+=%y                                " File type
set statusline+=%{SL('FugitiveStatusline')}
set statusline+=%#ErrorMsg#
if exists('*LinterStatus')
  set statusline+=%{SL('LinterStatus')}
elseif exists('*SyntasticStatuslineFlag')
  set statusline+=%{SL('SyntasticStatuslineFlag')}
endif
set statusline+=%*
set statusline+=%=                                " Right-aligned from here on
set statusline+=%-14.(%l,%c%V%)           " Line no., column/virtual column nos.
set statusline+=\ %P                              " Percentage through file

" }}}2

" => 7 multiple tab pages {{{2

set showtabline=1

" }}}2

" => 8 terminal {{{2

set ttyfast                 " Assume a fast terminal connection in console Vim

" }}}2

" => 9 using the mouse {{{2

if has('mouse')
  set mouse=a               " Automatically enable mouse usage
endif

" }}}2

" => 10 GUI {{{2

if has('gui_running')
  set guioptions-=T               " Remove toolbar
  if WINDOWS()
    " Windows GUI font (Consolas tends to leave artefacts)
    set guifont=DejaVu\ Sans\ Mono:h12:cANSI,Consolas:h12:cANSI
  else
    set guifont=DejaVu\ Sans\ Mono\ 12
  endif
endif

" }}}2

" 12 messages and info {{{2

" Abbrev. of messages (avoids 'hit enter'); suppresses startup credits
set shortmess+=atTI

set ruler

" }}}2

" 13 selecting text {{{2

set clipboard=unnamed       " Use system clipboard

" }}}2

" 14 editing text {{{2

" Keep undo history across sessions
if has('persistent_undo')
  if !isdirectory($HOME . '/.vim')
    call mkdir($HOME . '/.vim', 'p')
  endif
  if !isdirectory($HOME . '/.vim/undodir')
    call mkdir($HOME . '/.vim/undodir', 'p')
  endif
  set undodir=~/.vim/undodir
  set undofile
endif

" Allow backspacing over autoindent, line break, and start of insert
set backspace=indent,eol,start

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j " Delete comment character when joining commented lines
endif

set completeopt=menuone,longest,preview
set showmatch               " Show matching brackets/parentheses

" }}}2

" => 15 tabs and indenting {{{2

set autoread                " Reload files changed outside of Vim
set autoindent              " Indent at level of previous line

" }}}2

" => 16 folding {{{2

set nofoldenable            " Disable code folding

" }}}2

" => 18 mapping {{{2

" Use <C-L> to clear the highlighting of :set hlsearch.
nnoremap <silent> <C-L>
  \ :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>

" Use `jj' as an alias for Escape.
inoremap jj <Esc>

" `\cc' toggles the vertical ruler
nnoremap <Leader>cc :call ColorColumnToggle()<CR>

" `\ev' edits .vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<CR>

" `\sh' shows the  syntax highlighting group of the word the cursor is on
nnoremap <Leader>sh :call <SID>SynStack()<CR>

" `\st' launches Startify
nnoremap <Leader>st :Startify<CR>

" `\tt' toggles Tagbar
nnoremap <Leader>t :TagbarToggle<CR>

" `\<TAB>' toggles NERDTree
nnoremap <Leader><Tab> :NERDTreeToggle<CR>

set ttimeoutlen=50          " Make <Esc> faster

" }}}2

" => 19 reading and writing files {{{2

set modeline                " Modelines are sometimes disabled on Debian
set modelines=5
set fileformats=unix,dos

" AUTOMATIC BACKUPS =====================================================
" Derived from http://www.valmikam.com/2010/09/vim-auto-backup-configuration.html

" Avoid problems with file permissions
if $USER !=# 'root'

  "enable backup
  set backup
  "
  "Create a backup folder, I like to have it in $HOME/vimbackup/date/
  let g:backup_day = strftime('%Y.%m.%d')
  let g:backupdir = $HOME . '/vimbackup/' . g:backup_day
  silent! let g:xyz = mkdir(g:backupdir, 'p')
  "
  "Set the backup folder
  let g:backup_cmd = 'set backupdir=' . g:backupdir
  execute g:backup_cmd
  "
  "Create an extention for backup file, useful when you are modifying the
  "same file multiple times in a day. I like to have an extention with
  "time hour.min.sec
  let g:backup_time = strftime('.%H.%M.%S')
  let g:backup_cmd = 'set backupext='. g:backup_time
  execute g:backup_cmd
  "
  "test.cpp is going to be backed up as HOME/vimbackup/date/test.cpp.hour.min.sec

endif

" ===================================================== AUTOMATIC BACKUPS

" }}}2

" => 20 the swap file {{{2

set updatetime=750

" }}}2

" => 21 command line editing {{{2

set history=1000
set wildmenu                " Show list instead of just completing

" }}}2

" => 26 multi-byte characters {{{2

if has('multi_byte')
  set encoding=utf-8
endif

" }}}2

" => 27 various {{{2

" Better Unix / Windows compatibility
set viewoptions=folds,options,cursor,unix,slash

" }}}2

" }}}1

" => Plugins {{{1

" This plugin arrangement requires git (and curl, except in Windows
" CMD.EXE/Powershell
if executable('git') && (executable('curl') || executable('wget') || WINDOWS())

  " Only try to load plugins if vim-plug is installed
  if filereadable(expand('~/.vim/autoload/plug.vim'))

    " Set up bundle support
    if CMDEXE() || WINDOWS()
      set runtimepath=~/.vim,$VIMRUNTIME

    " Avoid multiple threads on CloudLinux and iSH
    elseif has('unix') && ($AGKDOT_SYSTEMINFO =~# 'lve' 
        \ || $AGKDOT_SYSTEMINFO =~# 'iSH'
        \ || $VIM !~# 'iVim'
        \ && system('uname -a') =~# 'lve')
      let g:plug_threads=1
    endif

    call plug#begin()

    " Bundles

    " General
    " Plug 'ctrlpvim/ctrlp.vim'
    Plug 'mhinz/vim-startify'
    if ALECompatible()
      Plug 'dense-analysis/ale'
    else
      Plug 'scrooloose/syntastic'
    endif
    if &term !=# 'win32'
      Plug 'ConradIrwin/vim-bracketed-paste'
    endif
    Plug 'sgur/vim-editorconfig'
    Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }
    if v:version > 703
          \ || v:version == 703 && has('patch1261') && has('patch1264')
      Plug 'jlanzarotta/bufexplorer'
    endif
    Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
    Plug 'tweekmonster/startuptime.vim', { 'on': 'StartupTime' }
    Plug 'tpope/vim-commentary'
    Plug 'ciaranm/securemodelines'
    Plug 'fedorenchik/AnsiEsc'
    
    " Git
    if (has('nvim') || has('patch-8.0.902')) && ! WSL2()
      Plug 'mhinz/vim-signify'
    else
      Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
    endif
    Plug 'tpope/vim-fugitive'
    Plug 'junegunn/gv.vim', { 'on': 'GV' }

    " CSS/SCSS/Sass
    Plug 'ap/vim-css-color', { 'for': 'css' }

    " VimL
    if ! ALECompatible() && !executable('vint')
      Plug 'ynkdir/vim-vimlparser', { 'for': 'vim' }
      Plug 'syngan/vim-vimlint', { 'for': 'vim' }
    endif

    " Color Schemes
    Plug 'jnurmine/Zenburn'

    " Apache logs
    Plug 'vim-scripts/httplog'

    call plug#end()

  else

    echom 'Installing vim-plug...'
    echo ''

    if CMDEXE() || WINDOWS()
      silent !mkdir \%USERPROFILE\%\.vim\autoload
      silent !git clone https://github.com/junegunn/vim-plug \%USERPROFILE\%\.vim\vim-plug
      silent !copy \%USERPROFILE\%\.vim\vim-plug\plug.vim \%USERPROFILE\%\.vim\autoload\plug.vim
      silent !rmdir /s /q \%USERPROFILE\%\.vim\vim-plug
    elseif executable('curl')
      !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    elseif executable('wget')
      !mkdir ~/.vim/autoload && wget -O ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    endif

    source $MYVIMRC

    echom 'Installing packages...'
    echo ''

    :PlugInstall

  endif
else
  if !has('iVim')
    if !executable('git')
      echom 'Please install git.'
    endif
    if !executable('curl') || !executable('wget')
      echom 'Please install curl or wget.'
    endif
  endif
  filetype plugin indent on   " Normally handled by vim-plug
endif

" }}}1

" => UI {{{1

" For compatibility with true-color terminals
if &term == 'xterm-direct'
  set termguicolors
endif

" Rule out certain Cygwin/MSYS2 shells in ConEmu
" Rule out cmd.exe and Powershell in the Windows Console
if &term !=# 'cygwin' && &term !=# 'win32'

  " ConEmu running cmd.exe or Powershell
  if $ConEmuDir !=# '' && CMDEXE()
    set term=xterm
    inoremap <Char-0x07F> <BS>  " Backspace
    nnoremap <Char-0x07F> <BS>
  endif

  if has('iVim')
    silent! colorscheme desert
  else
    let g:zenburn_high_Contrast = 1
    silent! colorscheme zenburn
  endif

else
  colorscheme industry
endif

syntax on

" }}}1

" => Netrw {{{1
let g:netrw_menu        = 1     " Netrw menu in gVim
let g:netrw_liststyle   = 3     " Tree mode
let g:netrw_silent      = 1

if CMDEXE() || WINDOWS()        " Normal Windows vim & gVIM use PUTTY cmds
  let g:netrw_cygwin    = 0
  let g:netrw_scp_cmd   = 'pscp -q -batch'
  let g:netrw_sftp_cmd  = 'psftp'   " Does not work yet
  let g:netrw_list_cmd  = 'plink HOSTNAME ls -Fa '
  let g:netrw_ssh_cmd   = 'plink -T -ssh'
  let g:netrw_rm_cmd    = 'plink HOSTNAME rm'
  let g:netrw_rmdir_cmd = 'plink HOSTNAME rmdir'
  let g:netrw_mkdir_cmd = 'plink HOSTNAME mkdir'
  let g:netrw_rmf       = 'plink HOSTNAME rm -f '
endif

" }}}1

" => Plugin-specific settings {{{1

" Startify
let g:startify_custom_header = [ '' ]

" Syntastic
if ! ALECompatible()
  let g:syntastic_php_checkers = ['php', 'phpcs', 'phpmd']
  " let g:syntastic_php_phpcs_args='--tab-width=4 --standard=agkozak'
  " let g:syntastic_wordpress_phpcs_standard = 'agkozak' " Default standard
  let g:syntastic_viml_checkers = ['vim-lint']
  let g:syntastic_javascript_checkers = ['eslint']
  let g:syntastic_check_on_open = 0
  let g:syntastic_check_on_wq = 0
  if CMDEXE() || WINDOWS()
    let g:syntastic_auto_loc_list = 1
  endif
endif

let g:is_posix=1

" CtrlP
" let g:ctrlp_custom_ignore = '\v[\/]Music$'

" NERDTree

let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '~'

" Tagbar
let g:tagbar_autofocus = 1

" Colorizer
" let g:colorizer_auto_filetype='css,scss,html'

" vim-signify
let g:signify_vcs_list = [ 'git' ]

" }}}1

" => Miscellaneous {{{1

" \cc toggles a vertical ruler in column 80 on and off
function! ColorColumnToggle() abort
  if &colorcolumn != 80
    set colorcolumn=80
  else
    set colorcolumn=0
  endif
endfunction

" Show syntax highlighting groups for word under cursor: `\sh`
function! <SID>SynStack() abort
  if !exists('*synstack')
    return
  endif
  " vint: -ProhibitUnnecessaryDoubleQuote
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunction

if has('autocmd')
  augroup VariousAutocmd
    autocmd!

    " Jump to last known position in file
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$")
          \ | execute "normal! g'\"" | endif

    " Syntax {{{2

    " Apache logs
    autocmd BufReadPost access.log* set filetype=httplog
    autocmd BufReadPost error.log* set filetype=httplog

    " Treat *.md files as Markdown, not Modula-2
    autocmd BufNewFile,BufReadPost *.md setlocal filetype=markdown linebreak

    " mintty config file syntax
    autocmd BufNewFile,BufReadPost .minttyrc set filetype=dosini

    " JetBrains IDE color schemes
    autocmd BufNewFile,BufReadPost *.icls set filetype=xml

    " }}}2
  augroup END
endif

" Enable fenced code block syntax highlighting in Markdown documents
let g:markdown_fenced_languages = ['html', 'javascript', 'css', 'python', 'bash=sh', 'sh']

set t_ut= " Disable background color erase

" rg/ag/ack {{{2

" Avoid problems with native Windows rg/ag 
" if ! has('win32unix') 

"   if executable('rg')
"     set grepprg=rg\ --vimgrep\ --noheading
"     let g:ctrlp_user_command = 'rg %s --files --color=never --glob ""'
"     let g:ctrlp_use_caching  = 0
"   elseif executable('ag')
"     set grepprg=ag\ --nogroup\ --nocolor
"     let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
"     let g:ctrlp_use_caching = 0
"   elseif executable('ack')
"     set grepprg=ack\ -aH
"   endif

" endif

" }}}2

" Project-Specific .vimrc.local files
" https://www.reddit.com/r/vim/comments/7iy03o/you_aint_gonna_need_it_your_replacement_for/
function! SourceProjectConfig() abort
  let l:projectfile = findfile('.vimrc.local', expand('%:p').';')
  if filereadable(l:projectfile)
    silent execute 'source' l:projectfile
  endif
endfunction

if has('autocmd')
  augroup LocalVimrc
    autocmd!
    autocmd BufRead,BufNewFile * call SourceProjectConfig()

    if has('nvim')
      autocmd DirChanged * call SourceProjectConfig()
    endif
  augroup END
endif

" statusline function (from https://github.com/tpope/tpope/blob/master/.vimrc)

if has('eval')
	function! SL(function) abort
	  if exists('*'.a:function)
	    return call(a:function,[])
	  else
	    return ''
	  endif
	endfunction
endif

" ALE linter status {{{2
" https://github.com/w0rp/ale#faq-statusline

function! LinterStatus() abort
  let l:counts = ale#statusline#Count(bufnr(''))

  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors

  return l:counts.total == 0 ? '[OK]' : printf(
        \   '[%dW %dE]',
        \   l:all_non_errors,
        \   l:all_errors
        \ )
endfunction

" }}}2

" }}}1

" .vimrc.local {{{1

" Source ~/.vimrc.local, if it exists
if filereadable(glob('~/.vimrc.local'))
  source ~/.vimrc.local
endif

" }}}1

" vim: fdm=marker:ts=2:et:sw=2:ai:sts=2
