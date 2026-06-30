set noswapfile
set rtp^=.
execute 'set rtp+=' . stdpath('data') . '/lazy/plenary.nvim'
runtime! plugin/plenary.vim
