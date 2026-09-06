local M = {}
M.defaults = {
  theme = 'gruvbox', background = 'dark', dashboard = true,
  explorer = { side = 'left', width = 32, hidden = false, auto_open = false },
  numbers = true, relative_numbers = false, indent = 2, mouse = true,
  clipboard = true, undo = true, mappings = true,
  projects = { root = '~/Projects', recent_limit = 20 },
  config_file = vim.fn.stdpath('config') .. '/init.lua',
  keys = {
    dashboard = '<leader>h', explorer = '<leader>e', files = '<leader>ff', search = '<leader>fg',
    settings = '<leader>,', copy = '<leader>y', paste = '<leader>p', undo = '<leader>u', redo = '<leader>U',
    delete_word = '<M-BS>', delete_line = '<D-BS>',
  },
}
function M.setup(opts)
  opts = vim.deepcopy(opts or {})
  -- Accept the compact standalone config as well as grouped plugin options.
  opts.editor = opts.editor or {}
  for old, new in pairs({ numbers='number', relative_numbers='relativenumber', indent='tabstop' }) do
    if opts[old] ~= nil then opts.editor[new] = opts[old] end
  end
  if opts.undo ~= nil then opts.persistent_undo = opts.undo end
  if opts.config_file then opts.settings_file = opts.config_file end
  if opts.projects and opts.projects.root then opts.projects_dir = opts.projects.root end
  if opts.keys and opts.keys.search then opts.keys.grep = opts.keys.search end
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts)
  M.options.config_file = M.options.settings_file
  local o = M.options
  assert(o.explorer.side == 'left' or o.explorer.side == 'right', 'Coffe: explorer.side must be left or right')
  assert(type(o.explorer.width) == 'number' and o.explorer.width >= 15, 'Coffe: explorer.width must be >= 15')
  assert(type(o.indent) == 'number' and o.indent >= 1, 'Coffe: indent must be positive')
  assert(type(o.projects.recent_limit) == 'number' and o.projects.recent_limit >= 1, 'Coffe: recent_limit must be positive')
  return o
end
return M
