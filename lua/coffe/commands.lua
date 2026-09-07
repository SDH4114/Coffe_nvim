local M = {}
function M.setup()
  local a, p = require('coffe.actions'), require('coffe.projects')
  local actions = {
    home = function() require('coffe.dashboard').open() end,
    files = a.files, search = a.search, explorer = a.explorer,
    settings = a.settings, new = p.create, projects = p.pick,
    help = function()
      local c = require('coffe').config
      local lines = { 'Coffe shortcuts', 'Leader: ' .. (vim.g.mapleader == ' ' and 'Space' or tostring(vim.g.mapleader)), '' }
      for _, name in ipairs(vim.fn.sort(vim.tbl_keys(c.keys))) do lines[#lines+1] = name .. ': ' .. tostring(c.keys[name]) end
      vim.list_extend(lines, { '', 'Cmd-C / V / X: copy / paste / cut (terminal support required)',
        'Cmd-Z / Shift-Cmd-Z: undo / redo; Cmd-S or Ctrl-S: save',
        'F8: delete whole line; native dd and diw stay available',
        'Space pn / po / pr: create / open / recent projects',
        'Space bn / bp / bd: next / previous / close buffer',
        'Native undo: u; redo: Ctrl-R; insert delete word: Ctrl-W',
        '', 'Offline explorer: Enter open, a create, r rename, D delete',
        'Offline explorer: . hidden, R refresh, q close',
        'Neo-tree: press ? in the tree for available actions', '', 'Close help: q / Esc' })
      vim.api.nvim_set_hl(0, 'CoffePickerNormal', { link = 'NormalFloat', default = true })
      vim.api.nvim_set_hl(0, 'CoffePickerBorder', { link = 'FloatBorder', default = true })
      vim.api.nvim_set_hl(0, 'CoffePickerTitle', { link = 'Title', default = true })
      local buf = require('coffe.util').scratch('coffe_help')
      require('coffe.util').lines(buf, lines)
      local width = math.max(1, math.min(78, vim.o.columns - 4))
      local height = math.max(1, math.min(#lines, vim.o.lines - 6))
      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        width = width,
        height = height,
        border = 'rounded',
        title = ' Coffe · Keyboard ',
        title_pos = 'center',
        footer = ' q / Esc close ',
        footer_pos = 'center',
        style = 'minimal',
      })
      vim.wo[win].winhighlight = 'NormalFloat:CoffePickerNormal,FloatBorder:CoffePickerBorder,FloatTitle:CoffePickerTitle'
      for _, key in ipairs({ 'q', '<Esc>' }) do vim.keymap.set('n', key, '<cmd>close<cr>', { buffer = buf }) end
    end,
  }
  local aliases = { CoffeFiles = 'files', CoffeSearch = 'search', CoffeExplorer = 'explorer',
    CoffeSettings = 'settings', CoffeCreateProject = 'new', CoffeProjects = 'projects', CoffeKeys = 'help' }
  for name, action in pairs(aliases) do vim.api.nvim_create_user_command(name, actions[action], { force = true }) end
  vim.api.nvim_create_user_command('Coffe', function(args)
    local action = actions[args.args == '' and 'home' or args.args]
    if action then action() else vim.notify('Coffe: unknown action ' .. args.args, vim.log.levels.WARN) end
  end, { nargs = '?', complete = function() return vim.tbl_keys(actions) end, force = true })
  vim.api.nvim_create_user_command('CoffeOpenProject', function(args)
    if args.args == '' then p.prompt_open() else p.open(args.args) end
  end, { nargs = '?', complete = 'dir', force = true })
end
return M
