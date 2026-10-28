local M = {}

local function write(path, contents)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  assert(
    vim.fn.writefile(
      type(contents) == "table" and contents or { contents },
      path
    ) == 0
  )
end

local function link(source, destination)
  local ok, err = vim.uv.fs_symlink(source, destination, {
    dir = true,
    junction = vim.fn.has("win32") == 1,
  })
  assert(ok, err)
end

---Start a complete editor with synthetic state and read-only plugin sources.
---@param repository string
---@param opts? {file?: string, directory?: boolean, init?: string, timeout?: integer, roslyn?: boolean}
---@return table
function M.open(repository, opts)
  opts = opts or {}
  local root = vim.fn.tempname()
  local windows = vim.fn.has("win32") == 1
  local data = windows and root .. "/local/nvim-data" or root .. "/data/nvim"
  local config = windows and root .. "/local/nvim" or root .. "/config/nvim"
  local plugin_data = vim.g.orbitvim_test_plugin_data_path
    or vim.env.ORBITVIM_TEST_PLUGIN_DATA
    or vim.fn.stdpath("data")
  for _, path in ipairs({
    data .. "/lazy",
    vim.fs.dirname(config),
    root .. "/project",
    root .. "/home",
    root .. "/tmp",
  }) do
    vim.fn.mkdir(path, "p")
  end
  local scan = assert(
    vim.uv.fs_scandir(plugin_data .. "/lazy"),
    "installed plugins are required"
  )
  while true do
    local name, kind = vim.uv.fs_scandir_next(scan)
    if not name then
      break
    end
    if kind == "directory" or kind == "link" then
      link(plugin_data .. "/lazy/" .. name, data .. "/lazy/" .. name)
    end
  end
  if vim.uv.fs_stat(plugin_data .. "/site") then
    link(plugin_data .. "/site", data .. "/site")
  end
  link(repository, config)

  -- Loading tools is inert; these files select no external language processes.
  vim.opt.runtimepath:prepend(repository)
  local tools, state = require("features.hangar.config"), {}
  for _, category in ipairs({ "lsp", "dap", "formatter", "linter" }) do
    state[category] = {}
    for name in pairs(tools[category]) do
      state[category][name] = false
    end
  end
  write(data .. "/tools.json", vim.json.encode(state))
  write(root .. "/settings.json", "{}")
  local fixture_path = vim.env.PATH
  if opts.roslyn then
    assert(
      vim.fn.isdirectory(plugin_data .. "/lazy/roslyn.nvim") == 1,
      "Roslyn sources are required; run just deps"
    )
    fixture_path =
      require("scripts.tests.roslyn_fixture").path(root .. "/bin", fixture_path)
  end
  if opts.file then
    write(root .. "/project/" .. opts.file, "")
  end
  local prelude = string.format(
    [[
vim.opt.rtp:prepend(%q)
vim.g.orbitvim_settings_path = %q
vim.g.orbitvim_session_errors = {}
local errors = {}
_G.orbitvim_session_health = function() return {errors=errors} end
vim.ui_attach(vim.api.nvim_create_namespace('orbitvim_session'), {ext_messages=true}, function(event, kind, content)
  if event == 'msg_show' and (kind == 'emsg' or kind == 'lua_error' or kind == 'echoerr') then
    local parts = {}
    for _, chunk in ipairs(content) do parts[#parts+1] = chunk[2] end
    errors[#errors+1] = table.concat(parts)
  end
end)
local schedule = vim.schedule
vim.schedule = function(callback)
  schedule(function()
    local ok, err = xpcall(callback, debug.traceback)
    if not ok then
      errors[#errors+1] = tostring(err)
      vim.g.orbitvim_session_errors = errors
    end
  end)
end
vim.api.nvim_create_autocmd('User', {pattern='VeryLazy', callback=function()
  vim.g.orbitvim_session_ready = true
end})
vim.notify = function(message, level, options)
  if level == vim.log.levels.ERROR then
    table.insert(errors, tostring(message))
    vim.g.orbitvim_session_errors = errors
  end
end
local options = require('core.lazy')
options.install = { missing = false, colorscheme = { 'nvchad' } }
options.checker = { enabled = false }
options.change_detection = { enabled = false, notify = false }
options.readme = { enabled = false }
options.lockfile = %q
options.dev = { path = %q, patterns = { '.' }, fallback = false }
]],
    repository,
    root .. "/settings.json",
    repository .. "/lazy-lock.json",
    plugin_data .. "/lazy"
  )
  local command = {
    vim.v.progpath,
    "--embed",
    "--headless",
    "-i",
    "NONE",
    "--cmd",
    "lua " .. prelude,
    "-u",
    opts.init or repository .. "/init.lua",
  }
  if opts.file then
    table.insert(command, root .. "/project/" .. opts.file)
  elseif opts.directory then
    table.insert(command, root .. "/project")
  end
  local stderr = {}
  local job = vim.fn.jobstart(command, {
    rpc = true,
    cwd = root .. "/project",
    clear_env = true,
    env = {
      PATH = fixture_path,
      PATHEXT = vim.env.PATHEXT,
      SystemRoot = vim.env.SystemRoot,
      COMSPEC = vim.env.COMSPEC,
      HOME = root .. "/home",
      USERPROFILE = root .. "/home",
      LOCALAPPDATA = root .. "/local",
      APPDATA = root .. "/roaming",
      XDG_CONFIG_HOME = windows and root .. "/local" or root .. "/config",
      XDG_DATA_HOME = windows and root .. "/local" or root .. "/data",
      XDG_STATE_HOME = root .. "/state",
      XDG_CACHE_HOME = root .. "/cache",
      NVIM_APPNAME = "nvim",
      NVIM_LOG_FILE = root .. "/nvim.log",
      TMPDIR = root .. "/tmp",
      TEMP = root .. "/tmp",
      TMP = root .. "/tmp",
      GIT_CONFIG_NOSYSTEM = "1",
    },
    on_stderr = function(_, lines)
      vim.list_extend(stderr, lines)
    end,
  })
  assert(job > 0, "could not start editor fixture")
  local session = { root = root, job = job, stderr = stderr }
  local timer = assert(vim.uv.new_timer())
  timer:start(
    opts.timeout or 30000,
    0,
    vim.schedule_wrap(function()
      session.timed_out = true
      pcall(vim.fn.jobstop, job)
    end)
  )
  local sequence = 0
  function session.exec(code, arguments)
    sequence = sequence + 1
    local response = root .. "/response-" .. sequence .. ".json"
    local wrapped = [[
local arguments, response = ...
local ok, value = pcall(function(...)
]] .. code .. "\n" .. [[
end, unpack(arguments))
vim.fn.writefile({vim.json.encode({ok=ok, value=value})}, response .. '.tmp')
assert(vim.uv.fs_rename(response .. '.tmp', response))
]]
    vim.rpcnotify(job, "nvim_exec_lua", wrapped, { arguments or {}, response })
    assert(
      vim.wait(opts.timeout or 30000, function()
        return vim.fn.filereadable(response) == 1 or session.timed_out
      end, 10),
      "editor request timed out"
    )
    assert(not session.timed_out, "editor session timed out")
    local result =
      vim.json.decode(table.concat(vim.fn.readfile(response), "\n"))
    assert(result.ok, result.value)
    return result.value
  end
  function session.close()
    timer:stop()
    timer:close()
    pcall(vim.rpcnotify, job, "nvim_command", "qa!")
    if vim.fn.jobwait({ job }, 1000)[1] == -1 then
      pcall(vim.fn.jobstop, job)
      vim.fn.jobwait({ job }, 1000)
    end
    vim.fn.delete(root, "rf")
  end
  local attached, err = pcall(function()
    vim.rpcnotify(job, "nvim_ui_attach", 120, 40, { rgb = true })
    assert(
      vim.wait(10000, function()
        return session.exec(
          "return vim.v.vim_did_enter == 1 and (not package.loaded.lazy or vim.g.orbitvim_session_ready == true)"
        )
      end, 20),
      "editor did not finish UI startup"
    )
  end)
  if not attached then
    session.close()
    error(tostring(err) .. "\n" .. table.concat(stderr, "\n"), 0)
  end
  return session
end

return M
