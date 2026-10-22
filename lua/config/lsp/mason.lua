local icons = require("config.icons")

return {
  PATH = "skip",

  ui = {
    icons = {
      package_pending = icons.mason.package_pending,
      package_installed = icons.mason.package_installed,
      package_uninstalled = icons.mason.package_uninstalled,
    },
  },

  max_concurrent_installers = 10,

  registries = {
    "github:mason-org/mason-registry",
  },
}
