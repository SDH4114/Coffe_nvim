local M = {}

local function keyboard_help()
  local c = require('coffe').config
  local leader = vim.g.mapleader == ' ' and 'Space' or tostring(vim.g.mapleader)
  local lines = {
    '  COFFE WORKSPACE', '',
    '  ' .. tostring(c.keys.palette) .. '   Command palette',
    '  ' .. tostring(c.keys.dashboard) .. '   Dashboard',
    '  ' .. tostring(c.keys.explorer) .. '   File explorer',
    '  ' .. tostring(c.keys.buffers) .. '   Switch buffers', '',
    '  FILES', '',
    '  ' .. tostring(c.keys.files) .. '   Find files',
    '  ' .. tostring(c.keys.search) .. '   Search project text',
    '  ' .. tostring(c.keys.recent) .. '   Recent files', '',
    '  PROJECTS', '',
    '  Space pn   Create project', '  Space po   Open project', '  Space pr   Recent and pinned projects', '',
    '  EDITING', '',
    '  Ctrl-S / Cmd-S   Save', '  F8 / Cmd-Backspace   Delete whole line',
    '  Native u / Ctrl-R   Undo / redo', '  Native dd / diw / Ctrl-W remain unchanged', '',
    '  OFFLINE EXPLORER', '',
    '  h/l collapse or expand   Enter/o open   s split   t tab',
    '  P preview   a create   r rename   D delete   m mark',
    '  . hidden files   R refresh   q close', '',
    '  PICKERS', '',
    '  type to filter   Ctrl-N/P or arrows select   Enter accept',
    '  Ctrl-O preview   Ctrl-X close item where supported   Esc close', '',
    '  Leader: ' .. leader,
  }
  local buf, win = require('coffe.ui').float({
    filetype = 'coffe_help', title = 'Coffe · Keyboard', footer = 'q / Esc close',
    width = 78, height = math.min(#lines, vim.o.lines - 6),
  })
  require('coffe.util').lines(buf, lines)
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, function() require('coffe.ui').close(win) end, { buffer = buf, silent = true })
  end
end

function M.setup()
  local a, p = require('coffe.actions'), require('coffe.projects')
  local actions = {
    home = function() require('coffe.dashboard').open() end,
    commands = a.palette, files = a.files, recent = a.recent, buffers = a.buffers,
    search = a.search, explorer = a.explorer, settings = a.settings,
    new = p.create, projects = p.pick, help = keyboard_help,
  }
  local aliases = {
    CoffeCommands = 'commands', CoffeFiles = 'files', CoffeRecent = 'recent', CoffeBuffers = 'buffers',
    CoffeSearch = 'search', CoffeExplorer = 'explorer', CoffeSettings = 'settings',
    CoffeCreateProject = 'new', CoffeProjects = 'projects', CoffeKeys = 'help',
  }
  for name, action in pairs(aliases) do vim.api.nvim_create_user_command(name, actions[action], { force = true }) end
  vim.api.nvim_create_user_command('Coffe', function(args)
    local action = actions[args.args == '' and 'home' or args.args]
    if action then action() else require('coffe.util').notify('Unknown action ' .. args.args, vim.log.levels.WARN) end
  end, { nargs = '?', complete = function() return vim.tbl_keys(actions) end, force = true })
  vim.api.nvim_create_user_command('CoffeOpenProject', function(args)
    if args.args == '' then p.prompt_open() else p.open(args.args) end
  end, { nargs = '?', complete = 'dir', force = true })
  vim.api.nvim_create_user_command('CoffePinProject', function()
    local pinned = p.toggle_pin(vim.fn.getcwd())
    require('coffe.util').notify(pinned and 'Project pinned' or 'Project unpinned')
  end, { force = true })
end

return M
