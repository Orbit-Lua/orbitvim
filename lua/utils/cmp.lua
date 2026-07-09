---@class Core.util.cmp
local M = {}

---@alias Core.util.cmp.Action fun():boolean?
---@type table<string, Core.util.cmp.Action>
M.actions = {
  snippet_forward = function()
    local luasnip_ok, luasnip = pcall(require, "luasnip")
    if luasnip_ok and luasnip.expand_or_jumpable() then
      vim.schedule(function()
        luasnip.expand_or_jump()
      end)
      return true
    end

    if vim.snippet and vim.snippet.active({ direction = 1 }) then
      vim.schedule(function()
        vim.snippet.jump(1)
      end)
      return true
    end
  end,
  snippet_backward = function()
    local luasnip_ok, luasnip = pcall(require, "luasnip")
    if luasnip_ok and luasnip.jumpable(-1) then
      vim.schedule(function()
        luasnip.jump(-1)
      end)
      return true
    end

    if vim.snippet and vim.snippet.active({ direction = -1 }) then
      vim.schedule(function()
        vim.snippet.jump(-1)
      end)
      return true
    end
  end,
  snippet_stop = function()
    local luasnip_ok, luasnip = pcall(require, "luasnip")
    if luasnip_ok then
      local current_nodes = luasnip.session.current_nodes
      if current_nodes[vim.api.nvim_get_current_buf()] then
        luasnip.unlink_current()
        return
      end
    end

    if vim.snippet then
      vim.snippet.stop()
    end
  end,
}

---@param actions string[]
---@param fallback? string|fun()
---@return fun(): boolean?
function M.map(actions, fallback)
  return function()
    for _, name in ipairs(actions) do
      if M.actions[name] then
        local action_result = M.actions[name]()
        if action_result then
          return true
        end
      end
    end
    return type(fallback) == "function" and fallback() or fallback
  end
end

---@alias Placeholder {n:number, text:string}

---@param snippet string
---@param fn fun(placeholder:Placeholder):string
---@return string
function M.snippet_replace(snippet, fn)
  return snippet:gsub("%$%b{}", function(m)
    local n, name = m:match("^%${(%d+):(.+)}$")
    return n and fn({ n = n, text = name }) or m
  end) or snippet
end

-- This function resolves nested placeholders in a snippet.
---@param snippet string
---@return string
function M.snippet_preview(snippet)
  local ok, parsed = pcall(function()
    return vim.lsp._snippet_grammar.parse(snippet)
  end)
  return ok and tostring(parsed)
    or M.snippet_replace(snippet, function(placeholder)
      return M.snippet_preview(placeholder.text)
    end):gsub("%$0", "")
end

-- This function replaces nested placeholders in a snippet with LSP placeholders.
---@param snippet string
---@return string
function M.snippet_fix(snippet)
  local texts = {} ---@type table<number, string>
  return M.snippet_replace(snippet, function(placeholder)
    texts[placeholder.n] = texts[placeholder.n]
      or M.snippet_preview(placeholder.text)
    return "${" .. placeholder.n .. ":" .. texts[placeholder.n] .. "}"
  end)
end

---Expands a snippet string, with automatic repair on parse failure.
---@param snippet string
function M.expand(snippet)
  -- Native sessions don't support nested snippet sessions.
  -- Always use the top-level session.
  -- Otherwise, when on the first placeholder and selecting a new completion,
  -- the nested session will be used instead of the top-level session.
  -- See: https://github.com/LazyVim/LazyVim/issues/3199
  local session = vim.snippet.active() and vim.snippet._session or nil

  local ok, err = pcall(vim.snippet.expand, snippet)
  if not ok then
    local fixed = M.snippet_fix(snippet)
    ok = pcall(vim.snippet.expand, fixed)

    local message = ok
        and "Failed to parse snippet,\nbut was able to fix it automatically."
      or ("Failed to parse snippet.\n" .. err)

    require("utils")[ok and "warn" or "error"](
      ([[%s
```%s
%s
```]]):format(message, vim.bo.filetype, snippet),
      { title = "vim.snippet" }
    )
  end

  -- Restore top-level session when needed
  if session then
    vim.snippet._session = session
  end
end

---@param opts blink.cmp.Config
function M.setup(opts)
  require("blink.cmp").setup(opts)
end

return M
