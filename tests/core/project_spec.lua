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

  it(
    "scopes tool evidence to the source project and rechecks changed manifests",
    function()
      local root = test.temp_dir("tool projects with spaces")
      local a, b = root .. "/a", root .. "/b"
      vim.fn.mkdir(a .. "/.git", "p")
      vim.fn.mkdir(b .. "/.git", "p")
      local filename = a .. "/src/view.tsx"
      test.write_file(
        root .. "/package.json",
        '{"dependencies":{"eslint":"1"}}'
      )
      test.write_file(
        b .. "/package.json",
        '{"devDependencies":{"tailwindcss":"1"}}'
      )
      assert.is_nil(project.tool_root(filename, "eslint"))
      assert.is_nil(project.tool_root(filename, "tailwindcss"))
      test.write_file(a .. "/package.json", "{broken")
      assert.is_nil(project.tool_root(filename, "eslint"))
      for _, section in ipairs({
        "dependencies",
        "devDependencies",
        "optionalDependencies",
        "peerDependencies",
      }) do
        test.write_file(
          a .. "/package.json",
          vim.json.encode({ [section] = { eslint = "1" } })
        )
        test.assert_path(a, project.tool_root(filename, "eslint"))
      end
      test.write_file(
        a .. "/package.json",
        '{"description":"eslint tailwindcss"}'
      )
      assert.is_nil(project.tool_root(filename, "eslint"))
      test.write_file(a .. "/eslint.config.mjs", "export default []")
      test.assert_path(a, project.tool_root(filename, "eslint"))
    end
  )

  it(
    "inherits workspace evidence within the nearest repository only",
    function()
      local root = test.temp_dir("tool workspace")
      vim.fn.mkdir(root .. "/.git", "p")
      local nested = root .. "/packages/app"
      test.write_file(
        root .. "/package.json",
        '{"devDependencies":{"tailwindcss":"1"}}'
      )
      test.write_file(nested .. "/package.json", "{}")
      test.assert_path(
        nested,
        project.tool_root(nested .. "/src/view.tsx", "tailwindcss")
      )
      test.write_file(nested .. "/.git", "gitdir: elsewhere")
      assert.is_nil(project.tool_root(nested .. "/src/view.tsx", "tailwindcss"))
      local standalone = test.temp_dir("tool standalone")
      test.write_file(
        standalone .. "/package.json",
        '{"dependencies":{"eslint":"1"}}'
      )
      test.write_file(standalone .. "/inner/package.json", "{}")
      assert.is_nil(project.tool_root(standalone .. "/inner/file.js", "eslint"))
      test.assert_path(
        standalone,
        project.tool_root(standalone .. "/src/file.js", "eslint")
      )
      assert.is_nil(project.tool_root("", "eslint"))
    end
  )

  it("resolves nearest and hoisted tool binaries within the project", function()
    local root = test.temp_dir("tool binaries with spaces")
    local app = root .. "/packages/app"
    vim.fn.mkdir(root .. "/.git", "p")
    test.write_file(root .. "/package.json", '{"dependencies":{"eslint":"1"}}')
    test.write_file(app .. "/package.json", "{}")
    local command = "probe" .. (vim.fn.has("win32") == 1 and ".cmd" or "")
    local function binary(directory)
      local path = directory .. "/node_modules/.bin/" .. command
      test.write_file(path, "fixture executable")
      if vim.fn.has("win32") == 0 then
        assert(vim.uv.fs_chmod(path, 448))
      end
      return path
    end
    local hoisted = binary(root)
    local filename = app .. "/src/file.js"
    test.assert_path(
      hoisted,
      project.tool_executable(filename, "eslint", "probe")
    )
    local nearest = binary(app)
    test.assert_path(
      nearest,
      project.tool_executable(filename, "eslint", "probe")
    )
    local isolated = root .. "/isolated"
    vim.fn.mkdir(isolated .. "/.git", "p")
    test.write_file(
      isolated .. "/package.json",
      '{"dependencies":{"eslint":"1"}}'
    )
    assert.equals(
      command,
      project.tool_executable(isolated .. "/file.js", "eslint", "probe")
    )
  end)

  it(
    "recognizes non-Node Tailwind evidence without executing configuration",
    function()
      local root = test.temp_dir("tool tailwind")
      for index, case in ipairs({
        {
          "theme/static_src/tailwind.config.ts",
          "throw new Error('must not execute')",
        },
        { "mix.lock", '%{\n  "tailwind": {:hex, :tailwind, "1"}\n}' },
        { "Gemfile.lock", "GEM\n  specs:\n    tailwindcss-rails (1)\n" },
      }) do
        local directory = root .. "/" .. index
        test.write_file(directory .. "/" .. case[1], case[2])
        test.assert_path(
          directory,
          project.tool_root(directory .. "/views/page.html", "tailwindcss")
        )
      end
      test.write_file(root .. "/postcss.config.js", "export default {}")
      test.write_file(root .. "/mix.lock", "# tailwind")
      assert.is_nil(project.tool_root(root .. "/page.html", "tailwindcss"))
    end
  )
end)
