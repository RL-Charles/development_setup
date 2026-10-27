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
    "MeanderingProgrammer/render-markdown.nvim",
    opts = function()
      -- render-markdown only draws a line under the header; add a ├─┼─┤ separator
      -- after every data row by extending its table border pass.
      local Render = require("render-markdown.render.markdown.table")
      if Render._row_separators then
        return
      end
      Render._row_separators = true
      local border = Render.border
      function Render:border(wrapped)
        border(self, wrapped)
        local rows, chars = self.data.rows, self.config.border
        local parts = vim.tbl_map(function(col)
          return chars[11]:rep(col.width)
        end, self.data.cols)
        local text = chars[4] .. table.concat(parts, chars[5]) .. chars[6]
        -- rows[1] is the header, which already has the delimiter row under it.
        for i = 2, #rows - 1 do
          local line = self:line():pad(self.data.layout.col):text(text, self.config.row)
          local virtual_line = self:indent():line(true):extend(line):get()
          if wrapped[i] then
            table.insert(wrapped[i], virtual_line)
          else
            self.marks:add(self.config, "virtual_lines", rows[i].node.start_row, 0, {
              virt_lines = { virtual_line },
            })
          end
        end
      end
    end,
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
