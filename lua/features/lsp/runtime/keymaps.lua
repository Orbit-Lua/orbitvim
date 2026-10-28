local window = require("utils.window")
local lsp_client = require("features.lsp.runtime.client")
local borders = require("shared.borders")

local M = {}

---@class Lsp.Keymap
---@field [1] string lhs
---@field [2] string|function|false rhs; false removes an inherited mapping
---@field desc? string
---@field mode? string|string[]
---@field has? string|string[] method names; "definition" means "textDocument/definition"
---@field cond? fun(): boolean
---@field nowait? boolean
---@field expr? boolean

local function float_opts(border, focus)
  local width, height = window.get_doc_size()
  return {
    focus = focus,
    silent = true,
    border = border,
    max_width = width,
    max_height = height,
  }
end

local function signature_help()
  vim.lsp.buf.signature_help(float_opts(borders.lsp.signature_help, false))
end

local function snacks_words_enabled()
  return require("snacks").words.is_enabled()
end

local function jump_reference(count, cycle)
  return function()
    require("snacks").words.jump(count * vim.v.count1, cycle)
  end
end

---@type Lsp.Keymap[]
local defaults = {
  {
    "<leader>cl",
    function()
      require("snacks").picker.lsp_config()
    end,
    desc = "lsp info",
  },
  {
    "gd",
    vim.lsp.buf.definition,
    desc = "goto definition",
    has = "definition",
  },
  { "gR", vim.lsp.buf.references, desc = "references", nowait = true },
  { "gI", vim.lsp.buf.implementation, desc = "goto implementation" },
  { "gy", vim.lsp.buf.type_definition, desc = "goto type definition" },
  { "gD", vim.lsp.buf.declaration, desc = "goto declaration" },
  {
    "K",
    function()
      vim.lsp.buf.hover(float_opts(borders.lsp.hover, true))
    end,
    desc = "hover",
    has = "hover",
  },
  { "gK", signature_help, desc = "signature help", has = "signatureHelp" },
  {
    "<m-k>",
    signature_help,
    mode = "i",
    desc = "signature help",
    has = "signatureHelp",
  },
  {
    "<leader>ca",
    function()
      vim.lsp.buf.code_action({
        -- refer to: https://github.com/pmizio/typescript-tools.nvim/issues/238#issuecomment-3114629296
        filter = function(action)
          return action.title ~= "Move to a new file"
            and action.title ~= "Move to file"
        end,
      })
    end,
    desc = "code action",
    mode = { "n", "v" },
    has = "codeAction",
  },
  {
    "<leader>cC",
    vim.lsp.codelens.run,
    desc = "run code lens",
    mode = { "n", "v" },
    has = "codeLens",
  },
  {
    "<leader>cc",
    function()
      -- Lenses are enabled per buffer on attach.
      local buffer = { bufnr = vim.api.nvim_get_current_buf() }
      vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled(buffer), buffer)
    end,
    desc = "toggle code lens",
    has = "codeLens",
  },
  {
    "<leader>ci",
    lsp_client.toggle_inlay_hints,
    desc = "toggle inlay hints",
    has = "inlayHint",
  },
  {
    "<leader>cR",
    function()
      require("snacks").rename.rename_file()
    end,
    desc = "rename file",
    has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
  },
  { "<leader>cr", vim.lsp.buf.rename, desc = "rename", has = "rename" },
  {
    "<leader>cA",
    lsp_client.action.source,
    desc = "code source action",
    has = "codeAction",
  },
  {
    "]]",
    jump_reference(1),
    desc = "next reference",
    has = "documentHighlight",
    cond = snacks_words_enabled,
  },
  {
    "[[",
    jump_reference(-1),
    desc = "prev reference",
    has = "documentHighlight",
    cond = snacks_words_enabled,
  },
  {
    "<a-n>",
    jump_reference(1, true),
    desc = "next reference",
    has = "documentHighlight",
    cond = snacks_words_enabled,
  },
  {
    "<a-p>",
    jump_reference(-1, true),
    desc = "prev reference",
    has = "documentHighlight",
    cond = snacks_words_enabled,
  },
}

---@param buffer integer
---@param method string|string[]
---@return boolean
function M.has(buffer, method)
  if type(method) == "table" then
    return vim.iter(method):any(function(name)
      return M.has(buffer, name)
    end)
  end
  method = method:find("/") and method or "textDocument/" .. method
  return vim.iter(vim.lsp.get_clients({ bufnr = buffer })):any(function(client)
    return client:supports_method(method, buffer)
  end)
end

---Default mappings followed by those of each attached server; for the same
---mode and lhs, the later definition wins.
---@param buffer integer
---@return table<string, Lsp.Keymap & {mode: string}>
local function resolve(buffer)
  local servers = require("features.lsp.config").servers
  local specs = vim.list_extend({}, defaults)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buffer })) do
    vim.list_extend(specs, (servers[client.name] or {}).keys or {})
  end

  local resolved = {}
  for _, spec in ipairs(specs) do
    local modes = spec.mode or "n"
    for _, mode in ipairs(type(modes) == "table" and modes or { modes }) do
      resolved[mode .. "\0" .. spec[1]] = vim.tbl_extend("force", spec, {
        mode = mode,
      })
    end
  end
  return resolved
end

---@param buffer integer
function M.on_attach(_, buffer)
  for _, spec in pairs(resolve(buffer)) do
    if
      spec[2]
      and (not spec.has or M.has(buffer, spec.has))
      and (not spec.cond or spec.cond())
    then
      vim.keymap.set(spec.mode, spec[1], spec[2], {
        buffer = buffer,
        desc = spec.desc,
        expr = spec.expr,
        nowait = spec.nowait,
        silent = true,
      })
    end
  end
end

return M
