-- Show hidden (dot) files in directory browsing and file pickers.
-- Neo-tree and Snacks both hide them by default.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = true,
          -- Keep gitignored dotfiles like .env visible.
          always_show_by_pattern = {
            ".*",
          },
          -- .git is huge and almost never useful in the tree.
          never_show = {
            ".git",
          },
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
          explorer = { hidden = true },
        },
      },
    },
  },
}
