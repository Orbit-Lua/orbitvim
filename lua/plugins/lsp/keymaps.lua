local ui = require("utils.ui")
local utils_lsp = require("utils.lsp")
local borders = require("config.borders")

local M = {}

---@type LazyKeysLspSpec[]|nil
M._keys = nil

---@alias LazyKeysOpts LazyKeysBase|{has?:string|string[], silent?:boolean, buffer:unknown, cond?:fun():boolean}
---@alias LazyKeysLspSpec LazyKeysSpec|{has?:string|string[], cond?:fun():boolean}
---@alias LazyKeysLsp LazyKeys|{has?:string|string[], cond?:fun():boolean}

---@return LazyKeysLspSpec[]
function M.get()
  if M._keys then
    return M._keys
  end
  M._keys = {
    {
      "<leader>cl",
      function()
        require("snacks").picker.lsp_config()
      end,
      desc = "Lsp Info",
    },
    {
      "gd",
      vim.lsp.buf.definition,
      desc = "Goto Definition",
      has = "definition",
    },
    { "gR", vim.lsp.buf.references, desc = "References", nowait = true },
    { "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
    { "gy", vim.lsp.buf.type_definition, desc = "Goto Type Definition" },
    { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
    {
      "K",
      function()
        return vim.lsp.buf.hover({
          focus = true,
          silent = true,
          border = borders.default,
          max_width = select(1, ui.get_doc_window_size()),
          max_height = select(2, ui.get_doc_window_size()),
        })
      end,
      desc = "Hover",
    },
    {
      "gK",
      function()
        return vim.lsp.buf.signature_help({
          focus = false,
          silent = true,
          max_width = select(1, ui.get_doc_window_size()),
          max_height = select(2, ui.get_doc_window_size()),
          border = borders.default,
        })
      end,
      desc = "Signature Help",
      has = "signatureHelp",
    },
    {
      "<m-k>",
      function()
        return vim.lsp.buf.signature_help({
          focus = false,
          silent = true,
          max_width = select(1, ui.get_doc_window_size()),
          max_height = select(2, ui.get_doc_window_size()),
          border = borders.default,
        })
      end,
      mode = "i",
      desc = "Signature Help",
      has = "signatureHelp",
    },
    {
      "<leader>ca",
      function()
        vim.lsp.buf.code_action({
          -- refer to: https://github.com/pmizio/typescript-tools.nvim/issues/238#issuecomment-3114629296
          filter = function(action)
            local exclude_actions =
              { ["Move to a new file"] = true, ["Move to file"] = true }
            return not exclude_actions[action.title]
          end,
        })
      end,
      desc = "Code Action",
      mode = { "n", "v" },
      has = "codeAction",
    },
    {
      "<leader>cC",
      vim.lsp.codelens.run,
      desc = "Run Codelens",
      mode = { "n", "v" },
      has = "codeLens",
    },
    {
      "<leader>cc",
      function()
        vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled())
      end,
      desc = "Toggle Display Codelens",
      mode = { "n" },
      has = "codeLens",
    },
    {
      "<leader>ci",
      utils_lsp.toggle_inlay_hints,
      desc = "Toggle Inlay Hints",
      mode = { "n" },
      has = "inlayHint",
    },
    {
      "<leader>cR",
      function()
        require("snacks").rename.rename_file()
      end,
      desc = "Rename File",
      mode = { "n" },
      has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
    },
    { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
    {
      "<leader>cA",
      utils_lsp.action.source,
      desc = "Source Action",
      has = "codeAction",
    },
    {
      "]]",
      function()
        require("snacks").words.jump(vim.v.count1)
      end,
      has = "documentHighlight",
      desc = "Next Reference",
      cond = function()
        return require("snacks").words.is_enabled()
      end,
    },
    {
      "[[",
      function()
        require("snacks").words.jump(-vim.v.count1)
      end,
      has = "documentHighlight",
      desc = "Prev Reference",
      cond = function()
        return require("snacks").words.is_enabled()
      end,
    },
    {
      "<a-n>",
      function()
        require("snacks").words.jump(vim.v.count1, true)
      end,
      has = "documentHighlight",
      desc = "Next Reference",
      cond = function()
        return require("snacks").words.is_enabled()
      end,
    },
    {
      "<a-p>",
      function()
        require("snacks").words.jump(-vim.v.count1, true)
      end,
      has = "documentHighlight",
      desc = "Prev Reference",
      cond = function()
        return require("snacks").words.is_enabled()
      end,
    },
  }

  return M._keys
end

---@param method string|string[]
function M.has(buffer, method)
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end
    return false
  end
  method = method:find("/") and method or "textDocument/" .. method
  local clients = utils_lsp.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    if client:supports_method(method) then
      return true
    end
  end
  return false
end

---@return LazyKeysLsp[]
function M.resolve(buffer)
  local Keys = require("lazy.core.handler.keys")
  if not Keys.resolve then
    return {}
  end
  local spec = vim.tbl_extend("force", {}, M.get())
  local opts = require("plugins.lsp.config")
  local clients = utils_lsp.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    local maps = opts.servers[client.name] and opts.servers[client.name].keys
      or {}
    vim.list_extend(spec, maps)
  end
  return Keys.resolve(spec)
end

function M.on_attach(_, buffer)
  local Keys = require("lazy.core.handler.keys")
  local keymaps = M.resolve(buffer)

  for _, keys in pairs(keymaps) do
    local has_capability = not keys.has or M.has(buffer, keys.has)
    local is_condition_met = not (
      keys.cond == false
      or ((type(keys.cond) == "function") and not keys.cond())
    )

    if has_capability and is_condition_met then
      ---@type LazyKeysOpts
      local opts = Keys.opts(keys)
      opts.cond = nil
      opts.has = nil
      opts.silent = opts.silent ~= false
      opts.buffer = buffer
      vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, {
        desc = opts.desc,
        noremap = opts.noremap,
        remap = opts.remap,
        expr = opts.expr,
        nowait = opts.nowait,
        buffer = opts.buffer,
        silent = opts.silent,
      })
    end
  end
end

return M
