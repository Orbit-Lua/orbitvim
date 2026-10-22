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
    -- Escape runs this on every press; a session exists only if LuaSnip loaded.
    local luasnip = package.loaded.luasnip
    if luasnip then
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

return M
