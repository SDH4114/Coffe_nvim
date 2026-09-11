-- Offline demo settings. Standalone setup uses ../coffe.lua instead.
return {
  theme = 'coffe', dashboard = true, ui = { statusline = true },
  projects = { root = '~/Projects', recent_limit = 20 },
  markdown = { wrap = true, outline_key = '<leader>mo', checkbox_key = '<leader>mx', follow_key = '<leader>mf' },
  notes = { path = '~/Documents/Coffe/inbox.md' }, sessions = { enabled = true, auto_restore = true },
  explorer = { side = 'left', width = 32, hidden = false, auto_open = false },
  numbers = true, relative_numbers = false, indent = 2,
  clipboard = true, undo = true, mappings = true,
  keys = { palette = '<leader><space>', explorer = '<leader>e', files = '<leader>ff', buffers = '<leader>bb',
    note = '<leader>mn', git = '<leader>gs', diff = '<leader>gd' },
}
