set runtimepath^=~/.vim/bundle/ctrlp.vim
set cursorline
set number
set hidden
set wildmenu
set showcmd
set hlsearch
set autoindent
set laststatus=2
set mouse=a
set cmdheight=2
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab smarttab
set omnifunc=syntaxcomplete#Complete

filetype indent plugin on
syntax on

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

"-- PLUGINS --"

call plug#begin()
Plug 'ternjs/tern_for_vim', {'do' : 'npm install' }
PlugIn 'Plug vim-scripts/delimitMate.vim'
call plug#end()
