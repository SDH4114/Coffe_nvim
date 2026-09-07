-- Offline demo settings. Standalone setup uses ../coffe.lua instead.
return {
  theme = 'coffe', dashboard = true, ui = { statusline = true },
  projects = { root = '~/Projects', recent_limit = 20 },
  explorer = { side = 'left', width = 32, hidden = false, auto_open = false },
  numbers = true, relative_numbers = false, indent = 2,
  clipboard = true, undo = true, mappings = true,
  keys = { palette = '<leader><space>', explorer = '<leader>e', files = '<leader>ff', buffers = '<leader>bb' },
}
