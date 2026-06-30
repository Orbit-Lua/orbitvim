-- LSP Lifecycle
--
-- 1. Start
-- 2. Initialize Handshake
--  - nvim send initialize request
--  - server response capabilities
-- 3. Attach
--  - attach client to current buffer
-- 4. Handlers
--  - ex. textDocument/hover

local M = {}

---@alias LspClientFilterFun fun(client: lsp.Client.filter):boolean
---@alias lsp.Client.filter {id?: number, bufnr?: number, name?: string, method?: string, filter?:LspClientFilterFun}

---@param opts? lsp.Client.filter
function M.get_clients(opts)
  local clients ---@type vim.lsp.Client[]
  if vim.lsp.get_clients then
    clients = vim.lsp.get_clients(opts)
  else
    ---@diagnostic disable-next-line: deprecated
    clients = vim.lsp.get_active_clients(opts)
    if opts and opts.method then
      ---@param client vim.lsp.Client
      clients = vim.tbl_filter(function(client)
        return client:supports_method(opts.method, opts.bufnr)
      end, clients)
    end
  end
  return opts and opts.filter and vim.tbl_filter(opts.filter, clients)
    or clients
end

---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
function M.on_attach(on_attach, name)
  return vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup(
      "UserLspAttach_" .. (name or "all"),
      { clear = false }
    ),
    callback = function(args)
      local buffer = args.buf ---@type number
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and (not name or client.name == name) then
        on_attach(client, buffer)
      end
    end,
  })
end

---Proxy table: indexing with an LSP action name returns a function that applies it.
---@type table<string, fun()>
M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler

---@param opts LspCommand
function M.execute(opts)
  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }
  if opts.open then
    local ok, trouble = pcall(require, "trouble")
    if ok then
      trouble.open({
        mode = "lsp_command",
        params = params,
      })
    end
  else
    local clients =
      vim.lsp.get_clients({ bufnr = 0, method = "workspace/executeCommand" })
    local client = clients[1]
    if client then
      return client:request("workspace/executeCommand", params, opts.handler, 0)
    end
  end
end

---@param fn fun(client:vim.lsp.Client, buffer):boolean?
---@param opts? {group?: integer}
function M.on_dynamic_capability(fn, opts)
  return vim.api.nvim_create_autocmd("User", {
    pattern = "LspDynamicCapability",
    group = opts and opts.group or vim.api.nvim_create_augroup(
      "UserLspDynamicCapability",
      { clear = false }
    ),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number
      if client then
        return fn(client, buffer)
      end
    end,
  })
end

---@type table<string, table<vim.lsp.Client, table<number, boolean>>>
M._supports_method = {}

function M.setup()
  local register_capability = vim.lsp.handlers["client/registerCapability"]
  vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
    ---@diagnostic disable-next-line: no-unknown
    local result = register_capability(err, res, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client then
      for buffer in pairs(client.attached_buffers) do
        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspDynamicCapability",
          data = { client_id = client.id, buffer = buffer },
        })
      end
    end
    return result
  end
  M.on_attach(M._check_methods)
  M.on_dynamic_capability(M._check_methods)
end

---@param client vim.lsp.Client
function M._check_methods(client, buffer)
  -- don't trigger on invalid buffers
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  -- don't trigger on non-listed buffers
  if not vim.bo[buffer].buflisted then
    return
  end
  -- don't trigger on nofile buffers
  if vim.bo[buffer].buftype == "nofile" then
    return
  end
  for method, clients in pairs(M._supports_method) do
    clients[client] = clients[client] or {}
    if not clients[client][buffer] then
      if client.supports_method and client:supports_method(method, buffer) then
        clients[client][buffer] = true
        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspSupportsMethod",
          data = { client_id = client.id, buffer = buffer, method = method },
        })
      end
    end
  end
end

---@param method string
---@param fn fun(client:vim.lsp.Client, buffer)
function M.on_supports_method(method, fn)
  M._supports_method[method] = M._supports_method[method]
    or setmetatable({}, { __mode = "k" })
  return vim.api.nvim_create_autocmd("User", {
    pattern = "LspSupportsMethod",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number
      if client and method == args.data.method then
        return fn(client, buffer)
      end
    end,
  })
end

---Toggles LSP inlay hints for the current buffer.
function M.toggle_inlay_hints()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

return M
