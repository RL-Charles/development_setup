-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Keep LazyVim defaults (relative numbers, 2-space indent, etc.).
-- Uncomment if you prefer Primeagen-style relative numbers already on:
-- vim.opt.relativenumber = true

-- VS Code Vim-style cursor: block in normal, thin bar in insert, underline in replace.
vim.opt.guicursor = {
  "n-v-c:block-Cursor/lCursor",
  "i-ci-ve:ver25-Cursor/lCursor",
  "r-cr:hor20-Cursor/lCursor",
  "o:hor50",
  "a:blinkon0",
}

-- Restore a bar when leaving Neovim so the shell isn't stuck with a block.
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    vim.opt.guicursor = "a:ver25"
  end,
})
