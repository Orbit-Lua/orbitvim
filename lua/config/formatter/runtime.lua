local M = {}

local icons = require("config").icons

local function result_message(display_name, elapsed, err, did_edit)
  if err then
    return string.format(
      "Formatting %s failed after %.1fs. See :ConformInfo",
      display_name,
      elapsed
    )
  end
  if did_edit then
    return string.format("Formatted %s in %.1fs", display_name, elapsed)
  end
  return string.format("%s is already formatted (%.1fs)", display_name, elapsed)
end

---@param bufnr? integer
function M.format(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.b[bufnr].nvim_config_formatting then
    vim.notify("This buffer is already being formatted", vim.log.levels.WARN, {
      title = "formatter",
      icon = icons.formatter.error,
    })
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local display_name = filename == "" and "[No Name]"
    or vim.fs.basename(filename)
  local started = vim.uv.hrtime()
  vim.b[bufnr].nvim_config_formatting = true

  local finished = false
  local function finish(err, did_edit)
    if finished then
      return
    end
    finished = true

    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].nvim_config_formatting = nil
    end

    local elapsed = (vim.uv.hrtime() - started) / 1e9
    vim.notify(
      result_message(display_name, elapsed, err, did_edit),
      err and vim.log.levels.ERROR or vim.log.levels.INFO,
      {
        title = "formatter",
        icon = err and icons.formatter.error or icons.formatter.success,
      }
    )
  end

  local ok, err = pcall(require("conform").format, {
    async = true,
    bufnr = bufnr,
    quiet = true,
  }, finish)

  if not ok then
    finish(tostring(err), false)
  end
end

return M
