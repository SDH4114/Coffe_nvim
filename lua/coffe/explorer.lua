local M = { expanded = {}, entries = {}, marked = {} }
local util = require('coffe.util')
local ns = vim.api.nvim_create_namespace('coffe_explorer')

local function current()
  if not M.win or not vim.api.nvim_win_is_valid(M.win) then return nil end
  return M.entries[vim.api.nvim_win_get_cursor(M.win)[1]]
end

local function highlights()
  local groups = {
    CoffeSidebarNormal = 'NormalFloat', CoffeSidebarTitle = 'Title', CoffeSidebarPath = 'Directory',
    CoffeSidebarSeparator = 'NonText', CoffeSidebarHint = 'Comment', CoffeSidebarDirectory = 'Directory',
    CoffeSidebarFile = 'Normal', CoffeSidebarSelection = 'Visual', CoffeSidebarGit = 'DiagnosticWarn',
    CoffeSidebarDiagnostic = 'DiagnosticError', CoffeSidebarMarked = 'Special',
  }
  for name, link in pairs(groups) do vim.api.nvim_set_hl(0, name, { link = link, default = true }) end
end

local function icon_for(entry)
  if entry.kind == 'directory' then return M.expanded[entry.path] and '▾ ' or '▸ ' end
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if ok then
    local icon = devicons.get_icon(entry.name, vim.fn.fnamemodify(entry.name, ':e'), { default = true })
    if icon then return icon .. ' ' end
  end
  return '· '
end

local function git_statuses()
  if vim.fn.executable('git') ~= 1 then return {} end
  local result = vim.system({ 'git', '-C', M.root, 'status', '--porcelain', '--untracked-files=all' }, { text = true }):wait()
  if result.code ~= 0 then return {} end
  local statuses = {}
  for line in (result.stdout or ''):gmatch('[^\n]+') do
    local status, path = line:sub(1, 2), line:sub(4):gsub('^"', ''):gsub('"$', '')
    statuses[path] = status:gsub('%s', '') ~= '' and status:gsub('%s', '') or 'M'
    local parent = vim.fs.dirname(path)
    while parent and parent ~= '.' do statuses[parent] = statuses[parent] or '•'; parent = vim.fs.dirname(parent) end
  end
  return statuses
end

local function diagnostic_count(path)
  local buffer = vim.fn.bufnr(path)
  if buffer < 0 or not vim.api.nvim_buf_is_loaded(buffer) then return 0 end
  local count = vim.diagnostic.count(buffer)
  return (count[vim.diagnostic.severity.ERROR] or 0) + (count[vim.diagnostic.severity.WARN] or 0)
end

local function update_winbar()
  local entry = current()
  if not M.win or not vim.api.nvim_win_is_valid(M.win) then return end
  local suffix = entry and vim.fn.fnamemodify(entry.path, ':~:.') or vim.fn.fnamemodify(M.root, ':~')
  vim.wo[M.win].winbar = '%#CoffeSidebarTitle# Coffe Files %=%#CoffeSidebarPath#' .. suffix:gsub('%%', '%%%%') .. ' '
end

function M.refresh(focus_path)
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then return end
  highlights()
  focus_path = focus_path or (current() and current().path)
  local width = M.win and vim.api.nvim_win_is_valid(M.win) and vim.api.nvim_win_get_width(M.win) or 30
  local root = vim.fn.fnamemodify(M.root, ':~')
  local lines = {
    '  ' .. root,
    '  ' .. string.rep('─', math.max(1, width - 4)),
    '  h/l tree · Enter open · ? help',
    '',
  }
  local statuses = git_statuses()
  M.entries = {}
  local function walk(dir, depth)
    local children = {}
    local ok = pcall(function()
      for name, kind in vim.fs.dir(dir) do
        if name ~= '.git' and (M.hidden or name:sub(1, 1) ~= '.') then
          children[#children + 1] = { name = name, kind = kind, path = dir .. '/' .. name }
        end
      end
    end)
    if not ok then return end
    table.sort(children, function(a, b)
      if (a.kind == 'directory') ~= (b.kind == 'directory') then return a.kind == 'directory' end
      return a.name:lower() < b.name:lower()
    end)
    for _, entry in ipairs(children) do
      local relative = entry.path:sub(#M.root + 2)
      entry.git = statuses[relative]
      entry.diagnostics = entry.kind == 'file' and diagnostic_count(entry.path) or 0
      local mark = M.marked[entry.path] and '● ' or '  '
      local suffix = (entry.git and (' ' .. entry.git) or '') .. (entry.diagnostics > 0 and (' !' .. entry.diagnostics) or '')
      lines[#lines + 1] = string.rep('  ', depth) .. mark .. icon_for(entry) .. entry.name .. suffix
      M.entries[#lines] = entry
      if entry.kind == 'directory' and M.expanded[entry.path] and depth < 30 then walk(entry.path, depth + 1) end
    end
  end
  walk(M.root, 0)
  if vim.tbl_isempty(M.entries) then lines[#lines + 1] = '  No files found' end
  util.lines(M.buf, lines)
  vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(M.buf, ns, 0, 2, { end_col = #lines[1], hl_group = 'CoffeSidebarPath' })
  vim.api.nvim_buf_set_extmark(M.buf, ns, 1, 2, { end_col = #lines[2], hl_group = 'CoffeSidebarSeparator' })
  vim.api.nvim_buf_set_extmark(M.buf, ns, 2, 0, { end_col = #lines[3], hl_group = 'CoffeSidebarHint' })
  local target_row
  for row, entry in pairs(M.entries) do
    if entry.path == focus_path then target_row = row end
    local group = M.marked[entry.path] and 'CoffeSidebarMarked'
      or (entry.diagnostics > 0 and 'CoffeSidebarDiagnostic')
      or (entry.git and 'CoffeSidebarGit')
      or (entry.kind == 'directory' and 'CoffeSidebarDirectory' or 'CoffeSidebarFile')
    vim.api.nvim_buf_set_extmark(M.buf, ns, row - 1, 0, { end_col = #lines[row], hl_group = group })
  end
  if target_row and M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_win_set_cursor(M.win, { target_row, 0 }) end
  update_winbar()
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    if #vim.api.nvim_tabpage_list_wins(0) == 1 then vim.cmd('vnew') end
    vim.api.nvim_win_close(M.win, true)
  end
  M.win = nil
end

local function loaded_inside(path)
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buffer)
    if vim.api.nvim_buf_is_loaded(buffer) and (name == path or name:sub(1, #path + 1) == path .. '/') then return true end
  end
  return false
end

local function editor_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft ~= 'coffe_explorer' and vim.api.nvim_win_get_config(win).relative == '' then return win end
  end
end

local function open_file(entry, command)
  if not entry then return end
  if entry.kind == 'directory' then M.expanded[entry.path] = not M.expanded[entry.path]; M.refresh(entry.path); return end
  if command == 'edit' then util.edit(entry.path); return end
  local target = editor_window()
  if target then vim.api.nvim_set_current_win(target) end
  local ok, err = pcall(vim.cmd[command], vim.fn.fnameescape(entry.path))
  if not ok then util.notify(err, vim.log.levels.ERROR) end
end

function M.open()
  if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_set_current_win(M.win); return end
  local opts = require('coffe.config').options.explorer
  highlights(); M.root = vim.fn.getcwd(); M.hidden = opts.hidden
  vim.cmd(opts.side == 'left' and 'topleft vnew' or 'botright vnew')
  M.win = vim.api.nvim_get_current_win(); M.buf = util.scratch('coffe_explorer')
  vim.api.nvim_win_set_buf(M.win, M.buf); vim.api.nvim_win_set_width(M.win, opts.width)
  vim.wo[M.win].winfixwidth = true; vim.wo[M.win].number = false; vim.wo[M.win].relativenumber = false
  vim.wo[M.win].signcolumn = 'no'; vim.wo[M.win].wrap = false; vim.wo[M.win].cursorline = true
  vim.wo[M.win].cursorlineopt = 'line'; vim.wo[M.win].foldcolumn = '0'; vim.wo[M.win].colorcolumn = ''
  vim.wo[M.win].winhighlight = 'Normal:CoffeSidebarNormal,NormalNC:CoffeSidebarNormal,EndOfBuffer:CoffeSidebarNormal,CursorLine:CoffeSidebarSelection'
  local function map(key, fn, desc) vim.keymap.set('n', key, fn, { buffer = M.buf, nowait = true, silent = true, desc = 'Coffe: ' .. desc }) end
  map('<CR>', function() open_file(current(), 'edit') end, 'open')
  map('l', function()
    local entry = current(); if not entry then return end
    if entry.kind == 'directory' and not M.expanded[entry.path] then M.expanded[entry.path] = true; M.refresh(entry.path)
    else open_file(entry, 'edit') end
  end, 'expand or open')
  map('h', function()
    local entry = current(); if not entry then return end
    if entry.kind == 'directory' and M.expanded[entry.path] then M.expanded[entry.path] = nil; M.refresh(entry.path); return end
    local parent = vim.fs.dirname(entry.path)
    if parent == M.root then return end
    M.expanded[parent] = nil; M.refresh(parent)
  end, 'collapse or parent')
  map('o', function() open_file(current(), 'edit') end, 'open file')
  map('s', function() open_file(current(), 'vsplit') end, 'open in vertical split')
  map('t', function() open_file(current(), 'tabedit') end, 'open in tab')
  map('P', function() local entry = current(); if entry and entry.kind == 'file' then require('coffe.ui').preview(entry.path) end end, 'preview file')
  map('m', function() local entry = current(); if entry then M.marked[entry.path] = not M.marked[entry.path]; M.refresh(entry.path) end end, 'mark entry')
  map('q', M.close, 'close explorer'); map('R', M.refresh, 'refresh explorer')
  map('.', function() M.hidden = not M.hidden; M.refresh() end, 'toggle hidden files')
  map('?', function() vim.cmd.CoffeKeys() end, 'keyboard guide')
  map('<2-LeftMouse>', function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == M.win and M.entries[mouse.line] then vim.api.nvim_win_set_cursor(M.win, { mouse.line, 0 }); open_file(current(), 'edit') end
  end, 'open with mouse')
  map('a', function()
    local entry = current()
    local parent = entry and (entry.kind == 'directory' and entry.path or vim.fs.dirname(entry.path)) or M.root
    vim.ui.input({ prompt = 'New path (end with / for folder): ', default = parent .. '/' }, function(path)
      if not path or path == '' then return end
      local folder = path:sub(-1) == '/'; path = util.path(path)
      if vim.uv.fs_stat(path) then util.notify('Path already exists', vim.log.levels.WARN); return end
      local ok, err = pcall(function()
        vim.fn.mkdir(folder and path or vim.fs.dirname(path), 'p')
        if not folder then local fd, reason = vim.uv.fs_open(path, 'wx', 420); assert(fd, reason); vim.uv.fs_close(fd) end
      end)
      if not ok then util.notify(tostring(err), vim.log.levels.ERROR) end
      M.expanded[parent] = true; M.refresh(path)
      if ok and not folder then util.edit(path) end
    end)
  end, 'create path')
  map('r', function()
    local entry = current(); if not entry then return end
    if loaded_inside(entry.path) then util.notify('Close buffers inside this path before renaming (:bdelete).', vim.log.levels.WARN); return end
    vim.ui.input({ prompt = 'Rename to: ', default = entry.path }, function(path)
      if not path or path == '' or path == entry.path then return end
      path = util.path(path)
      if vim.uv.fs_stat(path) then util.notify('Destination already exists', vim.log.levels.WARN); return end
      local ok, err = vim.uv.fs_rename(entry.path, path)
      if not ok then util.notify(err, vim.log.levels.ERROR) else M.expanded[path] = M.expanded[entry.path]; M.expanded[entry.path] = nil end
      M.refresh(path)
    end)
  end, 'rename path')
  map('D', function()
    local entry = current(); if not entry then return end
    if loaded_inside(entry.path) then util.notify('Close buffers inside this path before deleting (:bdelete).', vim.log.levels.WARN); return end
    vim.ui.select({ 'Cancel', 'Delete' }, { prompt = 'Permanently delete ' .. entry.name .. '? (folders must be empty)' }, function(choice)
      if choice ~= 'Delete' then return end
      local ok, err
      if entry.kind == 'directory' then ok, err = vim.uv.fs_rmdir(entry.path) else ok, err = vim.uv.fs_unlink(entry.path) end
      if not ok then util.notify(err, vim.log.levels.ERROR) else M.marked[entry.path] = nil end
      M.refresh()
    end)
  end, 'delete path')
  local group = vim.api.nvim_create_augroup('CoffeExplorer' .. M.buf, { clear = true })
  vim.api.nvim_create_autocmd('CursorMoved', { group = group, buffer = M.buf, callback = update_winbar })
  vim.api.nvim_create_autocmd('BufWipeout', { group = group, buffer = M.buf, once = true,
    callback = function() pcall(vim.api.nvim_del_augroup_by_id, group) end })
  M.refresh(); vim.api.nvim_set_current_win(M.win)
  local first
  for row in pairs(M.entries) do if not first or row < first then first = row end end
  if first then vim.api.nvim_win_set_cursor(M.win, { first, 0 }) end
end

function M.toggle() if M.win and vim.api.nvim_win_is_valid(M.win) then M.close() else M.open() end end
return M
