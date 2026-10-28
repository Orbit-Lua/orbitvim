local fs = require("utils.fs")
local settings = require("features.settings.config")
-- The JSON service normalizes Windows drive letters before matching patterns.
local settings_files = vim.tbl_map(function(path)
  return path:gsub("^%a:", string.lower)
end, settings.schema_paths())

---@type Lsp.Server.Module
return {
  servers = {
    jsonls = {
      settings = {
        json = {
          validate = { enable = true },
          schemas = {
            {
              fileMatch = settings_files,
              url = vim.uri_from_fname(settings.schema_path),
            },
          },
        },
      },
    },
    -- config ref: https://github.com/eclipse-lemminx/lemminx/blob/main/docs/Configuration.md
    lemminx = {
      settings = {
        xml = {
          fileAssociations = {
            {
              systemId = fs.schema_paths.ms_build,
              pattern = "**/*.csproj",
            },
          },
          completion = {
            autoCloseTags = true,
          },
          validation = {
            enabled = false,
          },
        },
      },
    },

    yamlls = {
      settings = {
        yaml = {
          validate = true,
          completion = true,
          hover = true,

          schemaStore = {
            enable = false,
            url = "",
          },

          -- ref: https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/assets/javascripts/editor/schema?ref_type=heads
          schemas = {
            ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = {
              ".gitlab-ci.yml",
              ".gitlab-ci.yaml",
              ".gitlab/ci/*.yml",
              ".gitlab/ci/*.yaml",
            },
          },
        },
      },
    },
  },
}
