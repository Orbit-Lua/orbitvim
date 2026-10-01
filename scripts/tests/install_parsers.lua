local languages = { "c_sharp", "markdown", "sql" }

local installed =
  require("nvim-treesitter").install(languages, { summary = true }):wait(300000)

assert(installed, "failed to install integration-test parsers")

for _, language in ipairs(languages) do
  local parser, err = vim.treesitter.get_string_parser("", language)
  assert(parser, "parser unavailable for " .. language .. ": " .. tostring(err))
  parser:parse()
end
