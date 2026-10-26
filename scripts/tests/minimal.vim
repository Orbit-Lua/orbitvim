set noswapfile
set shadafile=NONE

let s:plugin_data_path = empty($ORBITVIM_TEST_PLUGIN_DATA) ? stdpath('data') : $ORBITVIM_TEST_PLUGIN_DATA
let s:test_root = tempname()
call mkdir(s:test_root, 'p')

let g:orbitvim_test_root = s:test_root
let $XDG_CONFIG_HOME = s:test_root . '/config'
let $XDG_DATA_HOME = s:test_root . '/data'
let $XDG_CACHE_HOME = s:test_root . '/cache'
let $XDG_STATE_HOME = s:test_root . '/state'
call mkdir(stdpath('log'), 'p')
let g:orbitvim_test_plugin_data_path = s:plugin_data_path
let g:tool_state_path = s:test_root . '/tools.json'
let g:orbitvim_log_path = s:test_root . '/nvim-config.log'
let g:orbitvim_settings_path = s:test_root . '/settings.json'

function! s:cleanup_test_root() abort
  if isdirectory(s:test_root)
    call delete(s:test_root, 'rf')
  endif
endfunction

augroup OrbitVimTestCleanup
  autocmd!
  autocmd VimLeavePre * call <SID>cleanup_test_root()
augroup END

lua << EOF
local repository = vim.fn.getcwd()
vim.opt.runtimepath = { repository, vim.env.VIMRUNTIME, repository .. "/after" }
vim.opt.packpath = {}
package.path = repository .. "/?.lua;" .. package.path
EOF
execute 'set rtp+=' . fnameescape(s:plugin_data_path . '/lazy/plenary.nvim')
execute 'set rtp+=' . fnameescape(s:plugin_data_path . '/site')
runtime! plugin/plenary.vim
lua require('tests.helpers').setup()
