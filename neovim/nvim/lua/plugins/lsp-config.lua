return {
  "neovim/nvim-lspconfig",
  ---@class PluginLspOpts
  opts = {
    ---@type lspconfig.options
    servers = {
      -- pyright will be automatically installed with mason and loaded with lspconfig
      pyright = {
        settings = {
          pyright = {
            disableOrganizeImports = true, -- Ruff does imports
          },
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoImportCompletions = true,
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticSeverityOverrides = { -- Ruff
                reportUnusedImport = "none",
                reportUnusedVariable = "none",
              },
            },
          },
        },
      },
    },
  },
}
