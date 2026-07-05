local M = {}

local function merge_linters(lint, linters)
  for linter_name, linter in pairs(linters) do
    if
      type(linter) == "table" and type(lint.linters[linter_name]) == "table"
    then
      ---@diagnostic disable-next-line
      lint.linters[linter_name] =
        ---@diagnostic disable-next-line
        vim.tbl_deep_extend("force", lint.linters[linter_name], linter)
      if type(linter.prepend_args) == "table" then
        lint.linters[linter_name].args = lint.linters[linter_name].args or {}
        vim.list_extend(lint.linters[linter_name].args, linter.prepend_args)
      end
    else
      lint.linters[linter_name] = linter
    end
  end
end

local function normalize_windows_output(lint)
  if not require("utils.os").is_win() then
    return
  end

  -- On Windows, linters emit CRLF. Strip \r before parsers run to prevent ^M
  -- appearing in diagnostic messages.
  for _, linter in pairs(lint.linters) do
    if type(linter) == "table" and type(linter.parser) == "function" then
      local orig = linter.parser
      linter.parser = function(output, bufnr, linter_cwd)
        return orig(output:gsub("\r\n", "\n"), bufnr, linter_cwd)
      end
    end
  end
end

local function apply_service_order(linters_by_ft)
  local order = require("service.order")
  for filetype, linters in pairs(linters_by_ft) do
    linters_by_ft[filetype] =
      order.enabled_names_for_ft("linter", filetype, linters)
  end
end

local function debounce(ms, fn)
  local timer = vim.uv.new_timer()
  return function(...)
    local captured_args = { ... }
    if timer ~= nil then
      timer:start(ms, 0, function()
        timer:stop()
        vim.schedule_wrap(fn)(require("utils").unpack(captured_args))
      end)
    end
  end
end

local function build_runner(lint)
  local logger = require("utils.logger")

  return function()
    if vim.bo.buftype ~= "" then
      return
    end

    -- Use nvim-lint's logic first:
    -- * checks if linters exist for the full filetype first
    -- * otherwise will split filetype by "." and add all those linters
    -- * this differs from conform.nvim which only uses the first filetype that has a formatter
    local linter_names = lint._resolve_linter_by_ft(vim.bo.filetype)

    -- Create a copy of the names table to avoid modifying the original.
    linter_names = vim.list_extend({}, linter_names)

    -- Add fallback linters.
    if #linter_names == 0 then
      vim.list_extend(linter_names, lint.linters_by_ft["_"] or {})
    end

    -- Add global linters.
    vim.list_extend(linter_names, lint.linters_by_ft["*"] or {})

    -- Clear previous run errors for all candidate linters before this run.
    for _, linter_name in ipairs(linter_names) do
      logger.clear_source("linter", linter_name)
    end

    -- Filter out linters that don't exist or don't match the condition.
    local ctx = { filename = vim.api.nvim_buf_get_name(0) }
    ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
    linter_names = vim.tbl_filter(function(linter_name)
      ---@type Linter
      local linter = lint.linters[linter_name]
      if not linter then
        vim.notify("Linter not found: " .. linter_name, vim.log.levels.WARN)
        logger.write(
          "linter",
          "ERROR",
          linter_name,
          "linter definition not found",
          { kind = "definition_not_found" }
        )
      end
      return linter
        and not (
          type(linter) == "table"
          and linter.condition
          and not linter.condition(ctx)
        )
    end, linter_names)

    -- Pre-flight executable check for each resolved linter.
    for _, linter_name in ipairs(linter_names) do
      local linter = lint.linters[linter_name]
      if type(linter) == "table" and linter.cmd then
        local cmd = type(linter.cmd) == "function" and linter.cmd()
          or linter.cmd
        if vim.fn.executable(cmd) ~= 1 then
          logger.write(
            "linter",
            "ERROR",
            linter_name,
            "binary not found: " .. cmd,
            { kind = "binary_not_found" }
          )
        end
      end
    end

    -- Run linters and notify listeners so the Service Manager can refresh
    -- run-error state. NvimLintRunPost only fires when a run actually happens
    -- to avoid spurious re-renders on buffers with no linters.
    if #linter_names > 0 then
      vim.api.nvim_exec_autocmds(
        "User",
        { pattern = "NvimLintRunPost", modeline = false }
      )
      lint.try_lint(linter_names)
    end
  end
end

---@param opts Linter.Opts
function M.setup(opts)
  local lint = require("lint")

  merge_linters(lint, opts.linters)
  normalize_windows_output(lint)
  apply_service_order(opts.linters_by_ft)

  lint.linters_by_ft = opts.linters_by_ft

  vim.api.nvim_create_autocmd(opts.events, {
    group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
    callback = debounce(200, build_runner(lint)),
  })
end

return M
