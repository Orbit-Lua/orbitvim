local M = {}

local function merge_linters(lint, linters)
  for linter_name, linter in pairs(linters or {}) do
    if
      type(linter) == "table" and type(lint.linters[linter_name]) == "table"
    then
      lint.linters[linter_name] =
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

  for _, linter in pairs(lint.linters) do
    if type(linter) == "table" and type(linter.parser) == "function" then
      local parser = linter.parser
      linter.parser = function(output, bufnr, linter_cwd)
        return parser(output:gsub("\r\n", "\n"), bufnr, linter_cwd)
      end
    end
  end
end

local function lint_buffer(lint, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    lint.try_lint()
  end)
end

---@param opts Linter.Opts
function M.setup(opts)
  local lint = require("lint")
  merge_linters(lint, opts.linters)
  normalize_windows_output(lint)
  lint.linters_by_ft = opts.linters_by_ft

  local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
  local timers = {}

  vim.api.nvim_create_autocmd(opts.events, {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      local timer = timers[bufnr]
      if not timer then
        timer = vim.uv.new_timer()
        timers[bufnr] = timer
      end
      if not timer then
        return
      end

      timer:stop()
      timer:start(
        200,
        0,
        vim.schedule_wrap(function()
          lint_buffer(lint, bufnr)
        end)
      )
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      local timer = timers[args.buf]
      if timer then
        timer:stop()
        if not timer:is_closing() then
          timer:close()
        end
        timers[args.buf] = nil
      end
    end,
  })
end

return M
