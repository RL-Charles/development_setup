-- Markdown rendering comes from the lang.markdown extra (render-markdown.nvim).
local mdlint_config = vim.fn.stdpath("config") .. "/.markdownlint-cli2.yaml"

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", mdlint_config, "-" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", mdlint_config },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          -- marksman is .NET and aborts without libicu, which WSL Ubuntu lacks.
          cmd_env = { DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1" },
        },
      },
    },
  },
}
