-- Add to the plugins table in an existing lazy.nvim / LazyVim setup.
return {
  {
    "SDH4114/Coffe_nvim",
    lazy = false,
    priority = 1000,
    opts = {
      -- Your existing plugin manager and language tooling stay in charge.
      theme = "gruvbox",
      explorer = { side = "left", width = 32 },
      ui = { statusline = false }, -- keep your existing statusline
      config_file = vim.fn.stdpath("config") .. "/lua/plugins/coffe.lua",
    },
    config = function(_, opts) require("coffe").setup(opts) end,
  },
  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1100 },
  {
    "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
    opts = { window = { position = "left", width = 32 } },
  },
  { "nvim-telescope/telescope.nvim", branch = "0.1.x", cmd = "Telescope", dependencies = { "nvim-lua/plenary.nvim" } },
}
