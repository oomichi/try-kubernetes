Setup development env for writing golang (VimFilter)
====================================================

Ubuntu 16.04, x86_64

Install necessary library::

 $ su sudo -
 # export GOPATH=/home/oomichi/dev/go
 # go get -u golang.org/x/tools/cmd/goimports
 # go get -u golang.org/x/tools/cmd/godoc
 # go get -u golang.org/x/tools/cmd/cover
 # go get -u github.com/nsf/gocode
 # go get -u github.com/golang/lint/golint
 # go get -u github.com/rogpeppe/godef
 # go get -u github.com/jstemmer/gotags

It is not necessary to install cmd/vet because the latest repo
doesn't contain it and the operation runs successfully without it.

Install NeoBundle::

 $ mkdir -p ~/.vim/bundle
 $ git clone git://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim

Change ${HOME}/.vimrc and copy ftplugin-go.vim::

 $ cp vimrc ~/.vimrc
 $ mkdir -p ~/.vimrc/ftplugin
 $ cp ftplugin-go.vim ~/.vimrc/ftplugin/go.vim

Type :VimFilerTree on vim console to operate VimFilter

Reference
---------
* http://qiita.com/shiena/items/870ac0f1db8e9a8672a7

