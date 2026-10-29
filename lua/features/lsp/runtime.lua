local M = {}
local feature_options
local gated_roots = setmetatable({}, { __mode = "k" })

local function apply_condition(server, options)
  local condition = options.condition
  options.condition = nil
  if not condition then
    return
  end
  local upstream = vim.lsp.config[server] or {}
  local resolve = options.root_dir or upstream.root_dir
  if gated_roots[resolve] then
    resolve = gated_roots[resolve].resolve
  end
  local markers = options.root_markers or upstream.root_markers
  local workspace_required = options.workspace_required
  if workspace_required == nil then
    workspace_required = upstream.workspace_required
  end
  local function root_dir(bufnr, on_dir)
    if not condition(bufnr) then
      return
    end
    if type(resolve) == "function" then
      return resolve(bufnr, on_dir)
    end
    local root = resolve or (markers and vim.fs.root(bufnr, markers))
    if root or not workspace_required then
      on_dir(root)
    end
  end
  gated_roots[root_dir] = { resolve = resolve }
  options.root_dir = root_dir
end

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

---Blink's completion capabilities with the configured overrides; Neovim's
---defaults when Blink is unavailable.
---@param overrides? lsp.ClientCapabilities
---@return lsp.ClientCapabilities
function M.client_capabilities(overrides)
  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    return blink.get_lsp_capabilities(overrides, true)
  end
  return vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    overrides or {}
  )
end

---Registers all configured LSP servers with vim.lsp.
---@param opts Lsp.Config.Spec
M.register_servers = function(opts)
  require("features.theme.runtime").load_cache("lsp")

  local packages = require("features.hangar.config.packages")
  local state_mod = require("hangar.state")
  local default_lsp_config = {
    on_init = opts.on_init,
    capabilities = M.client_capabilities(opts.capabilities),
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

    apply_condition(server, server_opts)
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
  local icons = require("shared.icons")

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
local diagnostic_filter
M.install_diagnostic_filter = function()
  if
    vim.lsp.handlers["textDocument/publishDiagnostics"] == diagnostic_filter
  then
    return
  end
  local default_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

  diagnostic_filter = function(err, result, ctx, config)
    if result and result.diagnostics then
      local suppressed_patterns =
        require("features.messages.config.ignored").lsp
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
  vim.lsp.handlers["textDocument/publishDiagnostics"] = diagnostic_filter
end

---Activates optional LSP features (inlay hints, code lens).
---@param opts Lsp.Config.Spec
local feature_generation = 0
M.activate_features = function(opts)
  feature_generation = feature_generation + 1
  local generation = feature_generation
  local group =
    vim.api.nvim_create_augroup("OrbitVimLspFeatures", { clear = true })
  feature_options = opts
  local lsp_client = require("features.lsp.runtime.client")

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
      { refresh = true, group = group }
    )
  end

  -- Enabled lenses refresh themselves as the buffer changes.
  if opts.codelens.enabled then
    lsp_client.on_supports_method("textDocument/codeLens", function(_, buffer)
      vim.lsp.codelens.enable(true, { bufnr = buffer })
    end, { group = group })
  end

  local pending_refresh = {}
  vim.api.nvim_create_autocmd({ "LspDetach", "BufWipeout" }, {
    group = group,
    callback = function(event)
      for key, entry in pairs(pending_refresh) do
        if
          entry.buffer == event.buf
          and (
            event.event == "BufWipeout"
            or entry.client == event.data.client_id
          )
        then
          pending_refresh[key] = nil
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("LspProgress", {
    group = vim.api.nvim_create_augroup(
      "OrbitVimLspMethodRefresh",
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
            local entry = { buffer = buffer, client = client.id }
            pending_refresh[key] = entry
            vim.defer_fn(function()
              if
                generation ~= feature_generation
                or pending_refresh[key] ~= entry
              then
                return
              end
              pending_refresh[key] = nil
              local refreshed_client = vim.lsp.get_client_by_id(client.id)
              if
                refreshed_client and refreshed_client.attached_buffers[buffer]
              then
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
  local lsp_client = require("features.lsp.runtime.client")
  local keymaps = require("features.lsp.runtime.keymaps")
  lsp_client.setup()
  local group =
    vim.api.nvim_create_augroup("OrbitVimLspKeymaps", { clear = true })
  lsp_client.on_attach(keymaps.on_attach, nil, group)
  lsp_client.on_dynamic_capability(keymaps.on_attach, { group = group })

  M.configure_diagnostics(opts)
  M.install_diagnostic_filter()
  M.activate_features(opts)
  M.register_servers(opts)
end

return M
