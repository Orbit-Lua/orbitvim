local M = {}

-- LSP: lsp_config_name -> { mason, ft }
M.lsp = {
  pyright = { mason = "pyright", ft = { "python" } },
  ruff = { mason = "ruff", ft = { "python" } },
  roslyn = { mason = "roslyn", ft = { "cs" } },
  html = { mason = "html-lsp", ft = { "html" } },
  cssls = { mason = "css-lsp", ft = { "css" } },
  tailwindcss = {
    mason = "tailwindcss-language-server",
    ft = { "html", "css", "typescriptreact", "javascriptreact" },
  },
  dockerls = {
    mason = "dockerfile-language-server",
    ft = { "dockerfile" },
  },
  docker_compose_language_service = {
    mason = "docker-compose-language-service",
    ft = { "yaml.docker-compose" },
  },
  clangd = { mason = "clangd", ft = { "c", "cpp" } },
  bashls = { mason = "bash-language-server", ft = { "sh", "bash" } },
  marksman = { mason = "marksman", ft = { "markdown" } },
  prismals = { mason = "prisma-language-server", ft = { "prisma" } },
  tombi = { mason = "tombi", ft = { "toml" } },
  jsonls = { mason = "json-lsp", ft = { "json" } },
  lua_ls = { mason = "lua-language-server", ft = { "lua" } },
  gopls = { mason = "gopls", ft = { "go" } },
  powershell_es = { mason = "powershell-editor-services", ft = { "ps1" } },
  lemminx = { mason = "lemminx", ft = { "xml" } },
}

-- DAP: adapter type name (as used in dap.adapters) -> { mason?, ft, note? }
M.dap = {
  python = {
    mason = nil,
    ft = { "python" },
    note = "uses venv debugpy",
  },
  coreclr = { mason = "netcoredbg", ft = { "cs" } },
}

-- LINTER: individual linter ID (as used in nvim-lint) -> { mason, ft }
M.linter = {
  eslint_d = {
    mason = "eslint_d",
    ft = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
  },
  hadolint = { mason = "hadolint", ft = { "dockerfile" } },
  ["markdownlint-cli2"] = { mason = "markdownlint-cli2", ft = { "markdown" } },
  luacheck = { mason = "luacheck", ft = { "lua" } },
  sqlfluff = { mason = "sqlfluff", ft = { "sql", "mysql", "plsql" } },
}

-- FORMATTER: individual formatter ID (as used in conform.nvim) -> { mason, ft, note? }
-- ruff_* variants all map to the same "ruff" mason package
M.formatter = {
  stylua = { mason = "stylua", ft = { "lua" } },
  ruff_fix = { mason = "ruff", ft = { "python" } },
  ruff_organize_imports = { mason = "ruff", ft = { "python" } },
  ruff_format = { mason = "ruff", ft = { "python" } },
  shfmt = { mason = "shfmt", ft = { "sh" } },
  deno_fmt = {
    mason = "deno",
    ft = { "css", "html", "json", "markdown", "markdown.mdx" },
  },
  eslint_d = {
    mason = "eslint_d",
    ft = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
  },
  csharpier = { mason = "csharpier", ft = { "cs" } },
  ["markdownlint-cli2"] = {
    mason = "markdownlint-cli2",
    ft = { "markdown", "markdown.mdx" },
  },
  ["markdown-toc"] = {
    mason = "markdown-toc",
    ft = { "markdown", "markdown.mdx" },
  },
  sqlfluff = { mason = "sqlfluff", ft = { "sql", "mysql", "plsql" } },
  prisma_fmt = {
    mason = nil,
    ft = { "prisma" },
    note = "uses local node_modules",
  },
  tombi = { mason = "tombi", ft = { "toml" } },
}

-- Canonical default formatter order per ft — mirrors config/formatter/init.lua
-- Only needed for fts with multiple formatters; single-formatter fts are always sorted correctly
M.formatter_defaults = {
  python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
  markdown = { "deno_fmt", "markdownlint-cli2", "markdown-toc" },
  ["markdown.mdx"] = { "deno_fmt", "markdownlint-cli2", "markdown-toc" },
}

-- Canonical default linter order per ft
M.linter_defaults = {}

return M
