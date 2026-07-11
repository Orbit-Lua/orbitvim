local M = {}

local icons = require("config").icons

local function spinner_frame()
  local ok, spinners = pcall(require, "noice.util.spinners")
  return ok and spinners.spin("dots") or icons.misc.dots
end

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
  if vim.b[bufnr].orbit_formatting then
    vim.notify("This buffer is already being formatted", vim.log.levels.WARN, {
      orbit_formatter = "error",
      orbit_formatter_icon = icons.formatter.error,
    })
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local display_name = filename == "" and "[No Name]"
    or vim.fs.basename(filename)
  local started = vim.uv.hrtime()
  vim.b[bufnr].orbit_formatting = true

  local progress = require("utils.progress").start({
    message = "Formatting " .. display_name .. "…",
    notify_opts = {
      orbit_formatter = "progress",
      orbit_formatter_icon = spinner_frame(),
    },
    spinner = spinner_frame,
    spinner_field = "orbit_formatter_icon",
  })

  local finished = false
  local function finish(err, did_edit)
    if finished then
      return
    end
    finished = true
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].orbit_formatting = nil
    end

    local elapsed = (vim.uv.hrtime() - started) / 1e9
    local level = err and vim.log.levels.ERROR or vim.log.levels.INFO
    progress:finish({
      message = result_message(display_name, elapsed, err, did_edit),
      level = level,
      notify_opts = {
        orbit_formatter = err and "error" or "done",
        orbit_formatter_icon = err and icons.formatter.error
          or icons.formatter.success,
      },
    })
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
