local M = {}

-- Canonical registry for runtime development tools and installer dependencies.
-- Consumer-specific routing is derived in config/packages.lua.

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
  dockerls = { mason = "dockerfile-language-server", ft = { "dockerfile" } },
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
  yamlls = { mason = "yaml-language-server", ft = { "yaml" } },
}

M.dap = {
  python = { mason = nil, ft = { "python" }, note = "uses venv debugpy" },
  coreclr = { mason = "netcoredbg", ft = { "cs" } },
}

M.linter = {
  eslint_d = {
    mason = "eslint_d",
    ft = {
      "typescript",
      "javascript",
      "typescriptreact",
      "javascriptreact",
      "jsx",
    },
  },
  hadolint = { mason = "hadolint", ft = { "dockerfile" } },
  ["markdownlint-cli2"] = { mason = "markdownlint-cli2", ft = { "markdown" } },
  luacheck = {
    mason = nil,
    ft = { "lua" },
    note = "external/PATH; CI pins Luacheck independently of Mason",
  },
  sqlfluff = { mason = "sqlfluff", ft = { "sql", "mysql", "plsql" } },
}

M.formatter = {
  stylua = { mason = "stylua", ft = { "lua" }, order = 10 },
  ruff_fix = { mason = "ruff", ft = { "python" }, order = 10 },
  ruff_organize_imports = { mason = "ruff", ft = { "python" }, order = 20 },
  ruff_format = { mason = "ruff", ft = { "python" }, order = 30 },
  shfmt = { mason = "shfmt", ft = { "sh" }, order = 10 },
  deno_fmt = {
    mason = "deno",
    ft = {
      "css",
      "html",
      "typescript",
      "javascript",
      "typescriptreact",
      "javascriptreact",
      "jsx",
      "json",
      "jsonc",
    },
    order = 10,
  },
  eslint_d = {
    mason = "eslint_d",
    ft = {
      "typescript",
      "javascript",
      "typescriptreact",
      "javascriptreact",
      "jsx",
    },
    order = 20,
  },
  csharpier = { mason = "csharpier", ft = { "cs" }, order = 10 },
  ["markdownlint-cli2"] = {
    mason = "markdownlint-cli2",
    ft = { "markdown", "markdown.mdx" },
    order = 10,
  },
  ["markdown-toc"] = {
    mason = "markdown-toc",
    ft = { "markdown", "markdown.mdx" },
    order = 20,
  },
  sqlfluff = {
    mason = "sqlfluff",
    ft = { "sql", "mysql", "plsql" },
    order = 10,
  },
  prisma_fmt = {
    mason = nil,
    ft = { "prisma" },
    note = "uses local node_modules",
    order = 10,
  },
  tombi = { mason = "tombi", ft = { "toml" }, order = 10 },
  yamlfmt = { mason = "yamlfmt", ft = { "yaml" }, order = 10 },
}

M.parser = {
  lua = { ft = { "lua" } },
  luadoc = { ft = { "lua" } },
  printf = { ft = { "c", "cpp" } },
  vim = { ft = { "vim" } },
  vimdoc = { ft = { "help" } },
  html = { ft = { "html" } },
  css = { ft = { "css" } },
  javascript = { ft = { "javascript", "javascriptreact" } },
  typescript = { ft = { "typescript" } },
  tsx = { ft = { "typescriptreact", "javascriptreact" } },
  c = { ft = { "c" } },
  cpp = { ft = { "cpp" } },
  python = { ft = { "python" } },
  bash = { ft = { "sh", "bash" } },
  markdown = { ft = { "markdown", "markdown.mdx" } },
  sql = { ft = { "sql", "mysql", "plsql" } },
  prisma = { ft = { "prisma" } },
  comment = { ft = {} },
  c_sharp = { ft = { "cs" } },
  xml = { ft = { "xml" } },
  go = { ft = { "go" } },
  regex = { ft = {} },
  yaml = { ft = { "yaml" } },
}

for _, definition in pairs(M.parser) do
  definition.source = "treesitter"
end

M.package = {
  ["typescript-language-server"] = {
    source = "mason",
    role = "dependency",
    note = "provides the TypeScript runtime used by typescript-tools.nvim",
  },
}

for _, category in ipairs({ "lsp", "dap", "linter", "formatter" }) do
  for _, definition in pairs(M[category]) do
    definition.source = definition.mason and "mason" or "external"
  end
end

return M
