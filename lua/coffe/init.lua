local M = {}
local owned = {}
function M.setup(opts)
  assert(vim.fn.has('nvim-0.11') == 1, 'Coffe needs Neovim 0.11+')
  M.config = require('coffe.config').setup(opts)
  local c = M.config
  if vim.g.mapleader == nil then vim.g.mapleader = ' ' end
  vim.opt.background, vim.opt.termguicolors = c.background, true
  vim.opt.number, vim.opt.relativenumber = c.numbers, c.relative_numbers
  vim.opt.mouse = c.mouse and 'a' or ''
  vim.opt.expandtab, vim.opt.shiftwidth, vim.opt.tabstop = true, c.indent, c.indent
  vim.opt.ignorecase, vim.opt.smartcase = true, true
  vim.opt.splitright, vim.opt.splitbelow = true, true
  vim.opt.scrolloff = 5
  if c.clipboard and vim.fn.has('clipboard') == 1 then vim.opt.clipboard:append('unnamedplus') end
  if c.undo then
    local dir = vim.fn.stdpath('state') .. '/coffe/undo'
    vim.fn.mkdir(dir, 'p', 448)
    vim.opt.undodir, vim.opt.undofile = dir, true
  end
  if c.theme and not pcall(vim.cmd.colorscheme, c.theme) then vim.cmd.colorscheme('coffe') end
  local a, p = require('coffe.actions'), require('coffe.projects')
  for _, entry in ipairs(owned) do
    if vim.fn.maparg(entry.key, entry.mode, false, true).desc == entry.desc then
      pcall(vim.keymap.del, entry.mode, entry.key)
    end
  end
  owned = {}
  local function map(modes, key, action, desc)
    if not c.mappings or not key or key == '' then return end
    for _, mode in ipairs(type(modes) == 'table' and modes or { modes }) do
      -- Existing user mappings take precedence, including callback mappings.
      local existing = vim.fn.maparg(key, mode, false, true)
      if vim.tbl_isempty(existing) or existing.sid == -8 then
        local description = 'Coffe: ' .. desc
        vim.keymap.set(mode, key, action, { silent = true, desc = description })
        owned[#owned + 1] = { mode = mode, key = key, desc = description }
      end
    end
  end
  map('n', c.keys.explorer, a.explorer, 'Toggle file explorer')
  map('n', c.keys.files, a.files, 'Find files')
  map('n', c.keys.search, a.search, 'Search project text')
  map('n', c.keys.recent, a.recent, 'Recent files')
  map('n', c.keys.buffers, a.buffers, 'Switch buffers')
  map('n', c.keys.palette, a.palette, 'Command palette')
  map('n', c.keys.note, a.note, 'Quick note')
  map('n', c.keys.git, a.git, 'Git status')
  map('n', c.keys.diff, a.diff, 'Diff current file')
  map('n', c.keys.dashboard, function() require('coffe.dashboard').open() end, 'Home')
  map('n', c.keys.settings, a.settings, 'Settings')
  local register = c.clipboard and vim.fn.has('clipboard') == 1 and '+' or '"'
  map('n', c.keys.copy, '"' .. register .. 'yy', 'Copy line')
  map('x', c.keys.copy, '"' .. register .. 'y', 'Copy selection')
  map('n', c.keys.paste, '"' .. register .. 'p', 'Paste clipboard')
  map('x', c.keys.paste, '"' .. register .. 'P', 'Paste over selection')
  map('n', c.keys.undo, 'u', 'Undo')
  map('n', c.keys.redo, '<C-r>', 'Redo')
  map('n', c.keys.delete_word, 'diw', 'Delete word')
  map('i', c.keys.delete_word, '<C-w>', 'Delete previous word')
  map({ 'n', 'i' }, c.keys.delete_line, a.delete_line, 'Delete whole line')
  map({ 'n', 'i' }, '<F8>', a.delete_line, 'Delete whole line (terminal)')
  map({ 'n', 'i', 'x' }, '<D-v>', a.paste, 'Paste')
  map('x', '<D-c>', '"' .. register .. 'y', 'Copy')
  map('n', '<D-c>', '"' .. register .. 'yy', 'Copy line')
  map('x', '<D-x>', '"' .. register .. 'd', 'Cut')
  map('n', '<D-z>', 'u', 'Undo')
  map('i', '<D-z>', '<C-o>u', 'Undo')
  map('n', '<D-S-z>', '<C-r>', 'Redo')
  map('i', '<D-S-z>', '<C-o><C-r>', 'Redo')
  map({ 'n', 'i' }, '<C-s>', '<cmd>write<cr>', 'Save')
  map({ 'n', 'i' }, '<D-s>', '<cmd>write<cr>', 'Save')
  map('n', '<leader>pn', p.create, 'Create project')
  map('n', '<leader>po', p.prompt_open, 'Open project')
  map('n', '<leader>pr', p.pick, 'Recent projects')
  map('n', '<leader>bn', '<cmd>bnext<cr>', 'Next buffer')
  map('n', '<leader>bp', '<cmd>bprevious<cr>', 'Previous buffer')
  map('n', '<leader>bd', '<cmd>bdelete<cr>', 'Close buffer')
  map('n', '<leader>?', '<cmd>CfKeys<cr>', 'Show shortcuts')
  if c.ui and c.ui.statusline then require('coffe.statusline').setup() end
  local group = vim.api.nvim_create_augroup('Coffe', { clear = true })
  local function startup()
    if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == '' and vim.bo.buftype == ''
      and not vim.bo.modified and vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_get_current_line() == '' then
      if c.dashboard then require('coffe.dashboard').open() end
    elseif c.explorer.auto_open and vim.bo.buftype == '' then a.explorer(false) end
  end
  if vim.v.vim_did_enter == 1 then startup() else
    vim.api.nvim_create_autocmd('VimEnter', { group = group, once = true, callback = startup })
  end
  vim.api.nvim_create_autocmd('BufEnter', { group = group, callback = function()
    if vim.bo.buftype == '' then
      vim.wo.number, vim.wo.relativenumber = c.numbers, c.relative_numbers
      vim.wo.signcolumn = 'auto'
    end
  end })
  vim.api.nvim_create_autocmd('FileType', { group = group, pattern = 'markdown', callback = function(args)
    require('coffe.markdown').setup_buffer(args.buf)
  end })
  vim.api.nvim_create_autocmd('DiagnosticChanged', { group = group, callback = function() vim.cmd.redrawstatus() end })
  vim.api.nvim_create_autocmd({ 'BufWritePost', 'DirChanged' }, { group = group, callback = function()
    local tree = require('coffe.explorer')
    if tree.win and vim.api.nvim_win_is_valid(tree.win) then tree.root = vim.fn.getcwd(); tree.refresh() end
  end })
  require('coffe.commands').setup()
  require('coffe.sessions').setup()
  return M
end
return M
