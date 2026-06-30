local M = {}

local state_mod = require("service.state")
local logger = require("utils.logger")
local order = require("service.order")

local function is_configured_for_ft(lint, ft, name)
  return vim.tbl_contains(lint.linters_by_ft[ft] or {}, name)
end

local function wiring_status(name, meta)
  local lint_ok, lint = pcall(require, "lint")
  if not lint_ok then
    return nil, nil
  end

  local total = #(meta.ft or {})
  if total == 0 then
    return "no ft", "DiagnosticWarn"
  end

  local configured = 0
  for _, ft in ipairs(meta.ft or {}) do
    if is_configured_for_ft(lint, ft, name) then
      configured = configured + 1
    end
  end

  if configured == 0 then
    return "not wired", "DiagnosticWarn"
  elseif configured < total then
    return string.format("partly wired %d/%d", configured, total),
      "DiagnosticWarn"
  end
  return nil, nil
end

---@class Service.LinterDiagnosticMessage
---@field file string
---@field lnum integer
---@field col integer
---@field severity integer
---@field message string

---@class Service.LinterDiagnosticSummary
---@field error_count integer
---@field warn_count integer
---@field messages Service.LinterDiagnosticMessage[]

---Counts E/W diagnostics and collects messages for `linter_name` across all
---loaded buffers. Queries by nvim-lint's namespace (keyed by linter name) to
---avoid source-name mismatches (e.g. markdownlint-cli2 uses source "markdownlint").
---@param linter_name string
---@return Service.LinterDiagnosticSummary
function M.get_linter_diagnostics(linter_name)
  local ns_id = vim.api.nvim_get_namespaces()[linter_name]
  if not ns_id then
    return { error_count = 0, warn_count = 0, messages = {} }
  end

  local error_count = 0
  local warn_count = 0
  local messages = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      for _, diagnostic in
        ipairs(vim.diagnostic.get(bufnr, { namespace = ns_id }))
      do
        if diagnostic.severity == vim.diagnostic.severity.ERROR then
          error_count = error_count + 1
        elseif diagnostic.severity == vim.diagnostic.severity.WARN then
          warn_count = warn_count + 1
        end
        table.insert(messages, {
          file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t"),
          lnum = diagnostic.lnum + 1,
          col = diagnostic.col + 1,
          severity = diagnostic.severity,
          message = diagnostic.message,
        })
      end
    end
  end

  table.sort(messages, function(a, b)
    if a.severity ~= b.severity then
      return a.severity < b.severity
    end
    if a.file ~= b.file then
      return a.file < b.file
    end
    return a.lnum < b.lnum
  end)

  return {
    error_count = error_count,
    warn_count = warn_count,
    messages = messages,
  }
end

---@param opts Service.ApplyRuntimeOpts
---@return nil
function M.apply_runtime(opts)
  local name, meta, is_enabled = opts.name, opts.meta, opts.is_enabled
  local lint_ok, lint = pcall(require, "lint")
  if not lint_ok then
    return
  end
  for _, ft in ipairs(meta.ft or {}) do
    local list = lint.linters_by_ft[ft] or {}
    if is_enabled then
      if not vim.tbl_contains(list, name) then
        table.insert(list, name)
      end
    else
      for i = #list, 1, -1 do
        if list[i] == name then
          table.remove(list, i)
        end
      end
    end
    lint.linters_by_ft[ft] = order.enabled_names_for_ft("linter", ft, list)
  end
end

---@param opts Service.ApplyOrderOpts
---@return nil
function M.apply_order(opts)
  local ft, enabled_names = opts.ft, opts.enabled_names
  local lint_ok, lint = pcall(require, "lint")
  if not lint_ok then
    return
  end
  lint.linters_by_ft[ft] = enabled_names
end

---@param opts Service.EntryStatusOpts
---@return string, string
function M.entry_status(opts)
  local name, meta = opts.name, opts.meta
  if not state_mod.is_enabled("linter", name) then
    return "disabled", "Comment"
  end

  local wire_text, wire_hl = wiring_status(name, meta)
  if wire_text then
    return wire_text, wire_hl
  end

  local run_errors = logger.get_entries("linter", name)
  if #run_errors > 0 then
    local latest_error = run_errors[#run_errors]
    local status_text
    if latest_error.tags and latest_error.tags.kind == "binary_not_found" then
      status_text = "no binary"
    elseif
      latest_error.tags
      and latest_error.tags.kind == "definition_not_found"
    then
      status_text = "missing definition"
    else
      status_text = "error"
    end
    return status_text, "DiagnosticError"
  end
  local summary = M.get_linter_diagnostics(name)
  if summary.error_count > 0 then
    return summary.error_count .. "E " .. summary.warn_count .. "W",
      "DiagnosticError"
  elseif summary.warn_count > 0 then
    return summary.warn_count .. "W", "DiagnosticWarn"
  else
    return "ok", "DiagnosticOk"
  end
end

return M
