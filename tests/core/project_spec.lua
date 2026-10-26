describe("project root policy", function()
  local test = require("tests.helpers")
  local project = require("utils.project")
  local original_clients, markers
  before_each(function()
    original_clients, markers = vim.lsp.get_clients, project.root_pattern
  end)
  after_each(function()
    vim.lsp.get_clients, project.root_pattern = original_clients, markers
  end)
  it("discovers project roots from directory and file markers", function()
    local cases = {
      { marker = ".git", directory = true },
      { marker = "pyproject.toml", content = "[project]\n" },
      { marker = "go.mod", content = "module example.test/app\n" },
    }

    for index, case in ipairs(cases) do
      project.root_pattern = { case.marker }
      local root = test.temp_dir("root-marker-" .. index)
      local nested = root .. "/src/deep"
      vim.fn.mkdir(nested, "p")
      if case.directory then
        vim.fn.mkdir(root .. "/" .. case.marker, "p")
      else
        test.write_file(root .. "/" .. case.marker, case.content)
      end
      test.assert_path(
        root,
        project.get_root(nested .. "/main.lua"),
        case.marker
      )
    end
  end)

  it("prefers an attached LSP root for the current buffer", function()
    local root = test.temp_dir("lsp-root")
    vim.lsp.get_clients = function(opts)
      assert.equals(0, opts.bufnr)
      return { { config = { root_dir = root } } }
    end

    local resolved = project.get_root()
    assert.equals(root, resolved)
  end)

  it(
    "discovers markers for explicit paths and otherwise uses their directory",
    function()
      local root = test.temp_dir("marker-root")
      local nested = root .. "/src/deep"
      vim.fn.mkdir(root .. "/.git", "p")
      vim.fn.mkdir(nested, "p")

      test.assert_path(root, project.get_root(nested .. "/main.lua"))

      local standalone = test.temp_dir("standalone") .. "/query.sql"
      project.root_pattern = { "_orbitvim_missing_root_marker_" }
      local fallback = project.get_root(standalone)

      test.assert_path(vim.fs.dirname(standalone), fallback)
    end
  )
end)
