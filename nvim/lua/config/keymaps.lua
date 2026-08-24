-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- VS Code / Primeagen muscle memory: fuzzy-find files on Ctrl-p
-- Live grep stays on LazyVim default: <leader>sg
map("n", "<C-p>", function()
  LazyVim.pick("files")()
end, { desc = "Find Files (Root Dir)" })

-- Harpoon QWERTY aliases (LazyVim extra already sets <leader>H / <leader>h / <leader>1-9)
map("n", "<leader>a", function()
  require("harpoon"):list():add()
end, { desc = "Harpoon add file" })

-- Alt-1..4 jump without leader (use <leader>1-4 if the terminal eats Alt)
for i = 1, 4 do
  map("n", "<M-" .. i .. ">", function()
    require("harpoon"):list():select(i)
  end, { desc = "Harpoon to File " .. i })
end
