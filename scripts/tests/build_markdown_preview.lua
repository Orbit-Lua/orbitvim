vim.opt.runtimepath:prepend(vim.fn.getcwd())
package.path = vim.fn.getcwd() .. "/?.lua;" .. package.path
require("scripts.tests.build_fixture").run(
  "markdown-preview.nvim",
  function(directory)
    for _, plugin in ipairs(require("plugins.editor")) do
      if plugin[1] == "iamcco/markdown-preview.nvim" then
        plugin.build({ dir = directory })
      end
    end
    local platform = vim.fn.has("win32") == 1 and "win.exe" or "linux"
    if vim.fn.has("mac") == 1 then
      platform = vim.uv.os_uname().machine == "arm64" and "macos-arm64"
        or "macos"
    end
    local result = vim
      .system(
        { directory .. "/app/bin/markdown-preview-" .. platform, "--version" },
        { text = true }
      )
      :wait(10000)
    local info = vim.json.decode(
      table.concat(vim.fn.readfile(directory .. "/package.json"), "\n")
    )
    assert(result.code == 0, result.stderr)
    assert(
      vim.trim(result.stdout) == info.version,
      "Markdown preview executable has the wrong version"
    )
    print("Markdown preview installation and executable version passed")
  end
)
