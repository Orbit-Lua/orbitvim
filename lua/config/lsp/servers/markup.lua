local fs = require("utils.fs")
local settings = require("config.settings")
-- The JSON service normalizes Windows drive letters before matching patterns.
local settings_file = settings.path():gsub("^%a:", string.lower)

---@type Lsp.Server.Module
return {
  servers = {
    jsonls = {
      settings = {
        json = {
          validate = { enable = true },
          schemas = {
            {
              fileMatch = { settings_file },
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
