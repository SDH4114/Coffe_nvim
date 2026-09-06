local M = {}
function M.spec()
  return {
    { "ellisonleao/gruvbox.nvim", priority = 1000, lazy = false,
      config = function()
        require("gruvbox").setup({ contrast = "soft" })
        local c = require("coffe").config
        pcall(vim.cmd.colorscheme, c.theme)
      end },
    { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", cmd = "Neotree",
      dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
      opts = function()
        local c = require("coffe").config.explorer
        return { window = { position = c.side, width = c.width },
          filesystem = { follow_current_file = { enabled = true },
            filtered_items = { hide_dotfiles = false, hide_gitignored = true } } }
      end },
    { "nvim-telescope/telescope.nvim", branch = "0.1.x", cmd = "Telescope",
      dependencies = { "nvim-lua/plenary.nvim" }, opts = {} },
    { "nvim-lualine/lualine.nvim", event = "VeryLazy", opts = {
      options = { theme = "auto", globalstatus = true },
      sections = { lualine_c = { { "filename", path = 1 } } },
    } },
    { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "modern" } },
    { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, opts = {} },
    { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
    { "hrsh7th/nvim-cmp", event = "InsertEnter",
      dependencies = { "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-nvim-lsp" },
      config = function()
        local cmp = require("cmp")
        cmp.setup({
          snippet = { expand = function(args) vim.snippet.expand(args.body) end },
          mapping = cmp.mapping.preset.insert({
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<CR>"] = cmp.mapping.confirm({ select = false }),
            ["<C-e>"] = cmp.mapping.abort(),
          }),
          sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "path" }, { name = "buffer" } }),
        })
      end },
  }
end
return M
