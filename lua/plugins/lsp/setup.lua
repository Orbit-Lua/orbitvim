local M = {}

---@param opts Lsp.Config.Spec
M.register_servers = function(opts)
  require("config.theme").load_cache("lsp")

  local configs = require("config")
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
      for _, setting in ipairs(opts.disable_default_settings[server]) do
        server_opts[setting] = nil
      end
    end

    if opts.setup[server] then
      opts.setup[server]()
    end

    local ok, err = pcall(vim.lsp.config, server, server_opts)
    if ok then
      pcall(vim.lsp.enable, server)
    else
      vim.notify(
        "[lsp] " .. server .. ": " .. tostring(err),
        vim.log.levels.WARN
      )
    end
  end
end

---@param opts Lsp.Config.Spec
M.configure_diagnostics = function(opts)
  local configs = require("config")

  if
    type(opts.diagnostics.virtual_text) == "table"
    and opts.diagnostics.virtual_text.prefix == "icons"
  then
    opts.diagnostics.virtual_text.prefix = function(diagnostic)
      for severity_name, icon in pairs(configs.icons.diagnostics) do
        if
          diagnostic.severity == vim.diagnostic.severity[severity_name:upper()]
        then
          return icon
        end
      end
      return "●"
    end
  end

  vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
end

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
      result.diagnostics = vim.tbl_filter(function(diagnostic)
        for _, pattern in ipairs(suppressed_patterns) do
          if diagnostic.message:find(pattern) then
            return false
          end
        end
        return true
      end, result.diagnostics)
    end
    default_handler(err, result, ctx, config)
  end
end

---@param opts Lsp.Config.Spec
M.activate_features = function(opts)
  local utils_lsp = require("utils.lsp")

  if opts.inlay_hints.enabled then
    utils_lsp.on_supports_method(
      "textDocument/inlayHint",
      function(_, buffer, event)
        if
          vim.api.nvim_buf_is_valid(buffer)
          and vim.bo[buffer].buftype == ""
          and not vim.tbl_contains(
            opts.inlay_hints.exclude,
            vim.bo[buffer].filetype
          )
          and (
            not (event and event.refresh)
            or vim.lsp.inlay_hint.is_enabled({ bufnr = buffer })
          )
        then
          vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
      end,
      { refresh = true }
    )
  end

  if opts.codelens.enabled and vim.lsp.codelens then
    utils_lsp.on_supports_method("textDocument/codeLens", function(_, bufnr)
      vim.lsp.codelens.enable(true, { bufnr = bufnr })
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

  local pending_refresh = {}
  vim.api.nvim_create_autocmd("LspProgress", {
    group = vim.api.nvim_create_augroup(
      "UserLspSupportsMethodRefresh",
      { clear = true }
    ),
    pattern = "end",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      for buffer in pairs(client.attached_buffers) do
        if vim.api.nvim_buf_is_valid(buffer) then
          local key = client.id .. ":" .. buffer
          if not pending_refresh[key] then
            pending_refresh[key] = true
            vim.defer_fn(function()
              pending_refresh[key] = nil
              local refreshed_client = vim.lsp.get_client_by_id(client.id)
              if refreshed_client then
                utils_lsp.refresh_supported_methods(refreshed_client, buffer)
              end
            end, 100)
          end
        end
      end
    end,
  })
end

return M
