local M = {}
local feature_options

---Retain distinct findings even when their diagnostic messages match.
function M.publish_typescript_diagnostics(err, result, context, config)
  if result and result.diagnostics then
    local filtered = {}
    for _, diagnostic in ipairs(result.diagnostics) do
      if
        diagnostic.source == "tsserver"
        and not vim.iter(filtered):any(function(previous)
          return vim.deep_equal(previous, diagnostic)
        end)
      then
        table.insert(filtered, diagnostic)
      end
    end
    result = vim.tbl_extend("force", result, { diagnostics = filtered })
  end
  vim.lsp.diagnostic.on_publish_diagnostics(err, result, context, config)
end

function M.apply_inlay_hints(hints)
  local changed, seen = {}, {}
  local ok, err = pcall(function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      local buffers = vim.tbl_keys(client.attached_buffers)
      table.sort(buffers)
      for _, buffer in ipairs(buffers) do
        if
          not seen[buffer]
          and vim.api.nvim_buf_is_valid(buffer)
          and vim.bo[buffer].buftype == ""
          and client:supports_method("textDocument/inlayHint", buffer)
        then
          seen[buffer] = true
          local previous = vim.lsp.inlay_hint.is_enabled({ bufnr = buffer })
          local enabled = hints.enabled
            and not vim.tbl_contains(hints.exclude, vim.bo[buffer].filetype)
          if enabled ~= previous then
            table.insert(changed, { buffer = buffer, enabled = previous })
            vim.lsp.inlay_hint.enable(enabled, { bufnr = buffer })
          end
        end
      end
    end
  end)
  if not ok then
    local failures = {}
    for index = #changed, 1, -1 do
      local old = changed[index]
      local restored, restore_error =
        pcall(vim.lsp.inlay_hint.enable, old.enabled, { bufnr = old.buffer })
      if not restored then
        table.insert(failures, tostring(restore_error))
      end
    end
    if #failures > 0 then
      err = tostring(err)
        .. "; inlay hint rollback failed: "
        .. table.concat(failures, "; ")
        .. "; restart required"
    end
    error(err, 0)
  end
  if feature_options then
    feature_options.inlay_hints = vim.deepcopy(hints)
  end
end

---Registers all configured LSP servers with vim.lsp.
---@param opts Lsp.Config.Spec
M.register_servers = function(opts)
  require("core.theme").load_cache("lsp")

  local packages = require("config.packages")
  local state_mod = require("tool.state")
  local default_lsp_config = {
    on_init = opts.on_init,
    capabilities = opts.capabilities,
  }

  for _, server in ipairs(packages.lsp_servers) do
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
      local enable_ok, enable_err = pcall(vim.lsp.enable, server)
      if not enable_ok then
        vim.notify(
          "[lsp] "
            .. server
            .. " could not be enabled: "
            .. tostring(enable_err),
          vim.log.levels.WARN
        )
      end
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
  local icons = require("config.icons")

  if
    type(opts.diagnostics.virtual_text) == "table"
    and opts.diagnostics.virtual_text.prefix == "icons"
  then
    opts.diagnostics.virtual_text.prefix = function(diagnostic)
      for severity_name, icon in pairs(icons.diagnostics) do
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
      local suppressed_patterns = require("config.message_ignored").lsp
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

---Activates optional LSP features (inlay hints, code lens).
---@param opts Lsp.Config.Spec
M.activate_features = function(opts)
  feature_options = opts
  local lsp_client = require("runtime.lsp.client")

  do
    lsp_client.on_supports_method(
      "textDocument/inlayHint",
      function(_, buffer, event)
        if
          vim.api.nvim_buf_is_valid(buffer)
          and opts.inlay_hints.enabled
          and vim.bo[buffer].buftype == ""
          and not vim.tbl_contains(
            opts.inlay_hints.exclude,
            vim.bo[buffer].filetype
          )
        then
          if
            not (event and event.refresh)
            or vim.lsp.inlay_hint.is_enabled({ bufnr = buffer })
          then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
          end
        end
      end,
      { refresh = true }
    )
  end

  if opts.codelens.enabled and vim.lsp.codelens then
    lsp_client.on_supports_method("textDocument/codeLens", function(_, bufnr)
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
                lsp_client.refresh_supported_methods(refreshed_client, buffer)
              end
            end, 100)
          end
        end
      end
    end,
  })
end

function M.setup(opts)
  local lsp_client = require("runtime.lsp.client")
  lsp_client.setup()
  lsp_client.on_attach(function(client, buffer)
    require("runtime.lsp.keymaps").on_attach(client, buffer)
  end)
  lsp_client.on_dynamic_capability(require("runtime.lsp.keymaps").on_attach)

  M.configure_diagnostics(opts)
  M.install_diagnostic_filter()
  M.activate_features(opts)
  M.register_servers(opts)
end

return M
