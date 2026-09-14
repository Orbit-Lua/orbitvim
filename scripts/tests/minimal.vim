set noswapfile

let s:plugin_data_path = stdpath('data')
let s:test_root = tempname()
call mkdir(s:test_root, 'p')

let g:nvim_config_test_root = s:test_root
let g:nvim_config_test_plugin_data_path = s:plugin_data_path

function! s:cleanup_test_root() abort
  if isdirectory(s:test_root)
    call delete(s:test_root, 'rf')
  endif
endfunction

augroup NvimConfigTestCleanup
  autocmd!
  autocmd VimLeavePre * call <SID>cleanup_test_root()
augroup END

set rtp^=.
execute 'set rtp+=' . fnameescape(s:plugin_data_path . '/lazy/plenary.nvim')
runtime! plugin/plenary.vim
