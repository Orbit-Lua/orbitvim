local fs = require("utils.fs")

---@type Lsp.Server.Module
return {
  servers = {
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
}
