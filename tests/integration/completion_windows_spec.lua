describe("pinned completion window compatibility", function()
  it(
    "renders configured documentation and resizes actual Blink windows",
    function()
      local session = require("tests.support.session").open(vim.fn.getcwd(), {})
      local ok, err = pcall(function()
        session.exec([[
vim.api.nvim_exec_autocmds('InsertEnter', {})
local config = require('blink.cmp.config')
local docs = require('blink.cmp.completion.windows.documentation')
local menu = require('blink.cmp.completion.windows.menu')
local buffer = docs.win:get_buf()
config.completion.documentation.draw({
  item = { detail = 'example(value)', documentation = 'Example documentation' },
  window = docs.win,
  default_implementation = function(opts)
    opts = vim.tbl_extend('force', { bufnr = buffer, max_width = 60 }, opts)
    require('blink.cmp.lib.window.docs').render_detail_and_documentation(opts)
  end,
})
local content = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), '\n')
assert(content:find('example(value)', 1, true))
assert(content:find('Example documentation', 1, true))
vim.api.nvim_exec_autocmds('VimResized', {})
local sizes = require('utils.window').get_completion_float_sizes()
assert(menu.win.config.max_height == sizes.completion.height)
assert(docs.win.config.max_width == sizes.documentation.width)
assert(docs.win.config.max_height == sizes.documentation.height)
]])
        local health = session.exec("return orbitvim_session_health()")
        assert.same({}, health.errors)
      end)
      session.close()
      assert(ok, err)
    end
  )
  it(
    "finishes one actual Noice progress message without retaining its timer",
    function()
      local session = require("tests.support.session").open(vim.fn.getcwd(), {})
      local ok, err = pcall(function()
        session.exec([[
local progress = require('utils.progress').start({
  message='Synthetic formatting', interval=10,
  notify_opts={orbit_formatter='progress', orbit_formatter_icon='.'},
  spinner=function() return 'o' end, spinner_field='orbit_formatter_icon',
})
local manager = require('noice.message.manager')
local message = assert(manager.get_by_id(progress.notification.id))
assert(vim.wait(1000, function() return message.opts.orbit_formatter_icon == 'o' end, 10))
progress:finish({ message='Synthetic formatting complete', level=vim.log.levels.INFO,
  notify_opts={orbit_formatter='done'} })
assert(progress.timer == nil)
assert(message.opts.keep == nil and message.opts.orbit_formatter == 'done')
progress:finish({message='duplicate completion'})
assert(message:content():find('Synthetic formatting complete', 1, true))
]])
        local health = session.exec("return orbitvim_session_health()")
        assert.same({}, health.errors)
      end)
      session.close()
      assert(ok, err)
    end
  )
end)
