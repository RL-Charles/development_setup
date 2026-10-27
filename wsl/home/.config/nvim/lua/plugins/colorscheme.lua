-- Pin the colorscheme so clones get the same look (Tokyo Night, moon).
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "moon",
      -- Brighter comments: moon's #636da6 is 3.1:1 on the background and
      -- reads as fuzzy on the OLED panel; #828bb8 is 4.6:1.
      on_colors = function(colors)
        colors.comment = "#828bb8"
      end,
    },
  },
}
