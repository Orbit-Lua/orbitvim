local M = {}
local active_timers = {}
local setup_generation = 0

local health = require("hangar.health")

local function merge_linters(lint, linters)
  for linter_name, linter in pairs(linters) do
    if
      type(linter) == "table" and type(lint.linters[linter_name]) == "table"
    then
      ---@diagnostic disable-next-line
      lint.linters[linter_name] =
        ---@diagnostic disable-next-line
        vim.tbl_deep_extend("force", lint.linters[linter_name], linter)
    else
      lint.linters[linter_name] = linter
    end
  end
end

local wrapped = setmetatable({}, { __mode = "k" })

local function strip_carriage_returns(linter)
  if
    type(linter) == "table"
    and type(linter.parser) == "function"
    and not wrapped[linter.parser]
  then
    local parse = linter.parser
    linter.parser = function(output, bufnr, linter_cwd)
      return parse((output:gsub("\r\n", "\n")), bufnr, linter_cwd)
    end
    wrapped[linter.parser] = true
  end
  return linter
end

-- Windows linters emit CRLF; strip \r before parsing so diagnostics show no ^M.
-- Setup may run again, so parsers and factories are wrapped only once.
local function normalize_windows_output(lint)
  if not require("utils.os").is_win() then
    return
  end

  for name, linter in pairs(lint.linters) do
    if type(linter) == "function" and not wrapped[linter] then
      lint.linters[name] = function()
        return strip_carriage_returns(linter())
      end
      wrapped[lint.linters[name]] = true
    else
      strip_carriage_returns(linter)
    end
  end
end

---Resolve linters like nvim-lint: an exact filetype wins, otherwise each
---dot-separated part contributes its linters once, in order.
local function resolve_linters(lint, filetype)
  local exact = lint.linters_by_ft[filetype]
  if exact then
    return vim.list_extend({}, exact)
  end
  local names, seen = {}, {}
  for _, part in ipairs(vim.split(filetype, ".", { plain = true })) do
    for _, name in ipairs(lint.linters_by_ft[part] or {}) do
      if not seen[name] then
        seen[name] = true
        table.insert(names, name)
      end
    end
  end
  return names
end

local function apply_tool_order(linters_by_ft)
  local order = require("hangar.order")
  for filetype, linters in pairs(linters_by_ft) do
    linters_by_ft[filetype] = order.to_runtime(
      "linter",
      order.enabled_names_for_ft(
        "linter",
        filetype,
        order.from_runtime("linter", linters)
      )
    )
  end
end

local function build_runner(lint, skip_while_editing)
  local logger = require("utils.logger")

  ---@param editing boolean only TextChanged fired since the last run
  return function(bufnr, editing)
    if
      not vim.api.nvim_buf_is_valid(bufnr)
      or not vim.api.nvim_buf_is_loaded(bufnr)
    then
      return
    end

    vim.api.nvim_buf_call(bufnr, function()
      if vim.bo.buftype ~= "" or vim.bo.filetype == "bigfile" then
        return
      end

      local linter_names = resolve_linters(lint, vim.bo.filetype)
      if editing then
        linter_names = vim.tbl_filter(function(name)
          return not vim.tbl_contains(skip_while_editing, name)
        end, linter_names)
      end

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
          logger.write(
            "linter",
            "ERROR",
            linter_name,
            "linter definition not found",
            { kind = "definition_not_found" }
          )
        end
        return linter ~= nil
      end, linter_names)

      -- Run linters and notify listeners so Hangar can refresh
      -- run-error state. NvimLintRunPost only fires when a run actually happens
      -- to avoid spurious re-renders on buffers with no linters.
      if #linter_names > 0 then
        vim.api.nvim_exec_autocmds(
          "User",
          { pattern = "NvimLintRunPost", modeline = false }
        )
        lint.try_lint(linter_names, {
          filter = function(linter)
            if linter.condition and not linter.condition(ctx) then
              return false
            end
            local err = health.executable_error(linter)
            if err then
              logger.write(
                "linter",
                "ERROR",
                linter.name,
                err,
                { kind = "binary_not_found" }
              )
            end
            return true
          end,
        })
      end
    end)
  end
end

---@param opts Linter.Opts
function M.setup(opts)
  vim.env.ESLINT_D_PPID = vim.fn.getpid()
  setup_generation = setup_generation + 1
  local generation = setup_generation
  for bufnr, timer in pairs(active_timers) do
    timer:stop()
    timer:close()
    active_timers[bufnr] = nil
  end
  local lint = require("lint")

  merge_linters(lint, opts.linters)
  normalize_windows_output(lint)
  apply_tool_order(opts.linters_by_ft)

  lint.linters_by_ft = opts.linters_by_ft

  local group = vim.api.nvim_create_augroup("OrbitVimLint", { clear = true })
  local run = build_runner(lint, opts.skip_while_editing or {})
  local buffer_tokens = {}
  local editing = {}
  vim.api.nvim_create_autocmd(opts.events, {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      editing[bufnr] = editing[bufnr] ~= false and args.event == "TextChanged"
      buffer_tokens[bufnr] = (buffer_tokens[bufnr] or 0) + 1
      local token = buffer_tokens[bufnr]
      if generation ~= setup_generation then
        return
      end
      local timer = active_timers[bufnr]
      if not timer then
        timer = vim.uv.new_timer()
        active_timers[bufnr] = timer
      end
      if timer then
        timer:stop()
        timer:start(200, 0, function()
          timer:stop()
          vim.schedule(function()
            if
              generation ~= setup_generation or buffer_tokens[bufnr] ~= token
            then
              return
            end
            if active_timers[bufnr] == timer then
              active_timers[bufnr] = nil
              timer:close()
            end
            local only_edits = editing[bufnr] == true
            editing[bufnr] = nil
            run(bufnr, only_edits)
          end)
        end)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      local timer = active_timers[args.buf]
      if timer then
        timer:stop()
        timer:close()
        active_timers[args.buf] = nil
      end
      buffer_tokens[args.buf] = nil
      editing[args.buf] = nil
    end,
  })
end

return M
