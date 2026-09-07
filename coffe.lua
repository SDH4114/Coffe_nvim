-- Coffe settings. Restart Neovim after changing this file.
return {
  theme = "gruvbox",         -- any installed colorscheme; built-in fallback: coffe
  background = "dark",
  dashboard = true,
  clipboard = true,          -- use the system clipboard for normal copy/paste too
  undo = true,               -- remember undo history between launches
  ui = { statusline = true }, -- built-in fallback; lualine replaces it when available
  mouse = true,
  numbers = true,
  relative_numbers = false,
  indent = 2,
  explorer = { side = "left", width = 32, auto_open = false },
  projects = { root = "~/Projects", recent_limit = 20 },
  keys = {
    palette = "<leader><space>", explorer = "<leader>e", files = "<leader>ff", search = "<leader>fg",
    recent = "<leader>fr", buffers = "<leader>bb",
    dashboard = "<leader>h", settings = "<leader>,",
    copy = "<leader>y", paste = "<leader>p",
    undo = "<leader>u", redo = "<leader>U",
    delete_word = "<M-BS>", delete_line = "<D-BS>",
  },
  -- Standard lazy.nvim specs; add plugins or override bundled ones here.
  plugins = {
    -- { "numToStr/Comment.nvim", opts = {} },
    -- { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  },
}
