-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Neovim's inlay-hint renderer can briefly receive stale columns while a line
-- is being changed, producing `Invalid 'col': out of range` notifications.
-- Keep hints visible in Normal mode, but suspend them while editing.
local inlay_hint_group = vim.api.nvim_create_augroup("user_suspend_inlay_hints", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
  group = inlay_hint_group,
  callback = function(event)
    if vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }) then
      vim.b[event.buf].inlay_hints_suspended = true
      vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
    end
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = inlay_hint_group,
  callback = function(event)
    if not vim.b[event.buf].inlay_hints_suspended then
      return
    end

    vim.b[event.buf].inlay_hints_suspended = false
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(event.buf) then
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
      end
    end)
  end,
})
