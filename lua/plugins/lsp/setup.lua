local M = {}

---Registers all configured LSP servers with vim.lsp.
---@param opts Lsp.Config.Spec
M.register_servers = function(opts)
  local ok, err = pcall(function()
    dofile(vim.g.base46_cache .. "lsp")
  end)
  if not ok then
    vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
  end

  local configs = require("config")
  local state_mod = require("service.state")
  local default_lsp_config = {
    on_init = opts.on_init,
    capabilities = opts.capabilities,
  }

  for _, server in ipairs(configs.packages.lsp_servers) do
    local server_opts = vim.tbl_deep_extend(
      "force",
      default_lsp_config,
      opts.servers[server] or {}
    )

    if type(opts.disable_default_settings[server]) == "table" then
      for _, v in ipairs(opts.disable_default_settings[server]) do
        server_opts[v] = nil
      end
    end

    if opts.setup[server] then
      opts.setup[server]()
    end

    local server_ok, server_err = pcall(vim.lsp.config, server, server_opts)
    if server_ok and state_mod.is_enabled("lsp", server) then
      pcall(vim.lsp.enable, server)
    elseif not server_ok then
      vim.notify(
        "[lsp] " .. server .. ": " .. tostring(server_err),
        vim.log.levels.WARN
      )
    end
  end
end

---Applies diagnostic signs, virtual-text icon resolution, and commits the final config.
---@param opts Lsp.Config.Spec
M.configure_diagnostics = function(opts)
  local configs = require("config")

  if vim.fn.has("nvim-0.10.0") < 1 then
    if type(opts.diagnostics.signs) ~= "boolean" then
      for severity, icon in pairs(opts.diagnostics.signs.text) do
        local name =
          vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      end
    end
  end

  if
    type(opts.diagnostics.virtual_text) == "table"
    and opts.diagnostics.virtual_text.prefix == "icons"
  then
    opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") < 1
        and "●"
      or function(diagnostic)
        local icons = configs.icons.diagnostics
        for severity_name, icon in pairs(icons) do
          if
            diagnostic.severity
            == vim.diagnostic.severity[severity_name:upper()]
          then
            return icon
          end
        end
      end
  end

  vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
end

---Installs a middleware that silently drops diagnostics matching configured ignore patterns.
M.install_diagnostic_filter = function()
  local default_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

  vim.lsp.handlers["textDocument/publishDiagnostics"] = function(
    err,
    result,
    ctx,
    config
  )
    if result and result.diagnostics then
      local suppressed_patterns = require("config").message_ignored.lsp
      local filtered = {}
      for _, diagnostic in ipairs(result.diagnostics) do
        local is_suppressed = false
        for _, pattern in ipairs(suppressed_patterns) do
          if diagnostic.message:find(pattern) then
            is_suppressed = true
            break
          end
        end
        if not is_suppressed then
          table.insert(filtered, diagnostic)
        end
      end
      result.diagnostics = filtered
    end
    default_handler(err, result, ctx, config)
  end
end

---Activates optional LSP features (inlay hints, code lens). Requires Neovim >= 0.10.
---@param opts Lsp.Config.Spec
M.activate_features = function(opts)
  if vim.fn.has("nvim-0.10") < 1 then
    return
  end

  local utils_lsp = require("utils.lsp")

  if opts.inlay_hints.enabled then
    utils_lsp.on_supports_method("textDocument/inlayHint", function(_, buffer)
      if
        vim.api.nvim_buf_is_valid(buffer)
        and vim.bo[buffer].buftype == ""
        and not vim.tbl_contains(
          opts.inlay_hints.exclude,
          vim.bo[buffer].filetype
        )
      then
        vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
      end
    end)
  end

  if opts.codelens.enabled and vim.lsp.codelens then
    utils_lsp.on_supports_method("textDocument/codeLens", function(_, bufnr)
      vim.lsp.codelens.enable(true)
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup(
          "UserCodeLens_" .. bufnr,
          { clear = true }
        ),
        buffer = bufnr,
        callback = function()
          vim.lsp.codelens.enable(true, { bufnr = bufnr })
        end,
      })
    end)
  end
end

return M
