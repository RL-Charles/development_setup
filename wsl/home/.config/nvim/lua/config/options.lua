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

-- Show whitespace: tabs, trailing spaces, nbsp, line-overflow markers.
vim.opt.list = true
vim.opt.listchars = {
  tab = "▸ ",
  trail = "·",
  nbsp = "␣",
  extends = "»",
  precedes = "«",
}
-- Uncomment to also show a dot for every space (noisy):
-- vim.opt.listchars:append({ space = "·" })

-- 4-space indentation instead of LazyVim's 2.
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- LazyVim's ftplugins reset indent per filetype; force 4 everywhere.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = true
  end,
})
