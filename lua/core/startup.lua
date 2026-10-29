local M = {}

local state, failure = "pending", nil
local searcher, group

local function remove_searcher()
  for index, loader in ipairs(package.loaders) do
    if loader == searcher then
      table.remove(package.loaders, index)
      break
    end
  end
end

local function bootstrap(path)
  if not vim.uv.fs_stat(path) then
    local git = require("utils.os").is_win() and "git.exe" or "git"
    local output = vim.fn.system({
      git,
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      path,
    })
    if vim.v.shell_error ~= 0 or not vim.uv.fs_stat(path) then
      error(
        "Failed to bootstrap lazy.nvim (git clone exited "
          .. vim.v.shell_error
          .. "): "
          .. vim.trim(output)
      )
    end
    local lock_path = vim.fn.stdpath("config") .. "/lazy-lock.json"
    if vim.fn.filereadable(lock_path) == 1 then
      local lock =
        vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
      local revision = lock["lazy.nvim"] and lock["lazy.nvim"].commit
      if revision then
        local checkout = vim.fn.system({
          git,
          "-C",
          path,
          "checkout",
          "--detach",
          revision,
        })
        if vim.v.shell_error ~= 0 then
          error(
            "Failed to check out locked lazy.nvim revision: "
              .. vim.trim(checkout)
          )
        end
      end
    end
  end
  vim.opt.rtp:prepend(path)
end

local function activate(event)
  if state == "loaded" or state == "loading" then
    return
  end
  if state == "failed" then
    error(failure, 0)
  end
  local before = {}
  local replay = event
    and (
      event.event == "BufReadPre"
      or event.event == "BufNewFile"
      or event.event == "StdinReadPre"
    )
  if replay then
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event.event })) do
      if autocmd.group then
        before[autocmd.group] = true
      end
    end
  end
  state = "loading"
  remove_searcher()
  local ok, err = xpcall(function()
    bootstrap(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")
    -- Lazy checks this option before taking over runtime plugin sourcing.
    vim.go.loadplugins = true
    require("lazy").setup({ { import = "plugins" } }, require("core.lazy"))
    local theme = require("features.theme.runtime")
    theme.ensure_cache()
    theme.load_cache("defaults")
    theme.load_cache("statusline")
    require("utils.hl").setup()
  end, debug.traceback)
  vim.api.nvim_clear_autocmds({ group = group })
  if not ok then
    state = "failed"
    failure = "OrbitVim plugin startup failed: " .. tostring(err)
    error(failure, 0)
  end
  state = "loaded"
  if replay then
    -- New subscriptions missed the event that initialized their owners.
    -- Replay only new groups, so existing buffer observers do not run twice.
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event.event })) do
      if autocmd.group and not before[autocmd.group] then
        before[autocmd.group] = true
        vim.api.nvim_exec_autocmds(event.event, {
          group = autocmd.group,
          buffer = event.buf,
          modeline = false,
        })
      end
    end
  end
end

function M.setup()
  if state == "loaded" or state == "loading" then
    return
  end
  if state == "failed" then
    error(failure, 0)
  end
  remove_searcher()
  group = vim.api.nvim_create_augroup("OrbitVimPluginStartup", { clear = true })
  -- Keep runtime plugins under Lazy's ownership until its setup runs.
  vim.go.loadplugins = false
  searcher = function(name)
    activate()
    local loaded = package.loaded[name]
    if loaded then
      return function()
        return loaded
      end
    end
    -- Activation installs Lazy's loaders. Retry discovery without re-entering us.
    for _, find in ipairs(package.loaders) do
      local loader, data = find(name)
      if type(loader) == "function" then
        return loader, data
      end
    end
    return "\n\tno plugin module found after OrbitVim activation"
  end
  table.insert(package.loaders, searcher)
  vim.api.nvim_create_autocmd({
    "UIEnter",
    "BufReadPre",
    "BufNewFile",
    "StdinReadPre",
    "CmdUndefined",
    "ColorSchemePre",
  }, {
    group = group,
    nested = true,
    callback = activate,
    desc = "Initialize plugins on first use",
  })
  if
    #vim.api.nvim_list_uis() > 0
    or vim.fn.argc() > 0
    or not vim.uv.fs_stat(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")
  then
    activate()
  end
end

return M
