vim-go
======

Install necessary packages::

 $ mkdir ~/.vim/autoload
 $ mkdir ~/.vim/plugged
 $ curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
 $ git clone https://github.com/fatih/vim-go.git ~/.vim/plugged/vim-go

Edit ~/.vimrc::

 " NOTE: The following is for vim-go
 call plug#begin()
 Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
 call plug#end()
 map <C-b> :GoBuild<CR>
 map <C-j> :cnext<CR>
 map <C-k> :cprevious<CR>
 set autowrite

Build packages on vim command::

 :GoInstallBinaries 

Ref: https://github.com/hnakamur/vim-go-tutorial-ja#%E3%82%AF%E3%82%A4%E3%83%83%E3%82%AF%E3%82%BB%E3%83%83%E3%83%88%E3%82%A2%E3%83%83%E3%83%97

