local M = { expanded = {}, entries = {} }
local util = require('coffe.util')
local ns = vim.api.nvim_create_namespace('coffe_explorer')
local function current() return M.entries[vim.api.nvim_win_get_cursor(0)[1]] end
local function highlights()
  vim.api.nvim_set_hl(0, 'CoffeSidebarNormal', { link = 'NormalFloat', default = true })
  vim.api.nvim_set_hl(0, 'CoffeSidebarTitle', { link = 'Title', default = true })
  vim.api.nvim_set_hl(0, 'CoffeSidebarPath', { link = 'Directory', default = true })
  vim.api.nvim_set_hl(0, 'CoffeSidebarSeparator', { link = 'NonText', default = true })
  vim.api.nvim_set_hl(0, 'CoffeSidebarHint', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'CoffeSidebarDirectory', { link = 'Directory', default = true })
  vim.api.nvim_set_hl(0, 'CoffeSidebarFile', { link = 'Normal', default = true })
  vim.api.nvim_set_hl(0, 'CoffeSidebarSelection', { link = 'Visual', default = true })
end
function M.refresh()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then return end
  highlights()
  local width = M.win and vim.api.nvim_win_is_valid(M.win) and vim.api.nvim_win_get_width(M.win) or 30
  local root = vim.fn.fnamemodify(M.root, ':~')
  local lines = {
    '  COFFE FILES',
    '  ' .. root,
    '  ' .. string.rep('─', math.max(1, width - 4)),
    '  Enter open    a new',
    '  r rename      D delete',
    '  . hidden      R refresh',
    '  q close',
    '',
  }
  M.entries = {}
  local function walk(dir, depth)
    local children={}
    local ok=pcall(function()
      for name, kind in vim.fs.dir(dir) do
        if name ~= '.git' and (M.hidden or name:sub(1,1) ~= '.') then children[#children+1]={name=name,kind=kind,path=dir..'/'..name} end
      end
    end)
    if not ok then return end
    table.sort(children,function(a,b)
      if (a.kind=='directory') ~= (b.kind=='directory') then return a.kind=='directory' end
      return a.name:lower()<b.name:lower()
    end)
    for _, entry in ipairs(children) do
      local directory=entry.kind=='directory'
      lines[#lines+1]=string.rep('  ',depth+1)..(directory and (M.expanded[entry.path] and '▾ ' or '▸ ') or '  ')..entry.name
      M.entries[#lines]=entry
      if directory and M.expanded[entry.path] and depth<30 then walk(entry.path,depth+1) end
    end
  end
  walk(M.root,0)
  util.lines(M.buf,lines)
  vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(M.buf, ns, 0, 2, { end_col = 13, hl_group = 'CoffeSidebarTitle' })
  vim.api.nvim_buf_set_extmark(M.buf, ns, 1, 2, { end_col = 2 + #root, hl_group = 'CoffeSidebarPath' })
  vim.api.nvim_buf_set_extmark(M.buf, ns, 2, 2, { end_col = #lines[3], hl_group = 'CoffeSidebarSeparator' })
  for row = 4, 7 do
    vim.api.nvim_buf_set_extmark(M.buf, ns, row - 1, 0, { end_col = #lines[row], hl_group = 'CoffeSidebarHint' })
  end
  for row, entry in pairs(M.entries) do
    vim.api.nvim_buf_set_extmark(M.buf, ns, row - 1, 0, {
      end_col = #lines[row],
      hl_group = entry.kind == 'directory' and 'CoffeSidebarDirectory' or 'CoffeSidebarFile',
    })
  end
end
function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    if #vim.api.nvim_tabpage_list_wins(0)==1 then vim.cmd('vnew') end
    vim.api.nvim_win_close(M.win,true)
  end
  M.win=nil
end
function M.open()
  if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_set_current_win(M.win); return end
  local opts=require('coffe.config').options.explorer
  highlights()
  M.root=vim.fn.getcwd(); M.hidden=opts.hidden
  vim.cmd(opts.side=='left' and 'topleft vnew' or 'botright vnew')
  M.win=vim.api.nvim_get_current_win()
  M.buf=util.scratch('coffe_explorer')
  vim.api.nvim_win_set_buf(M.win,M.buf)
  vim.api.nvim_win_set_width(M.win,opts.width)
  vim.wo.winfixwidth=true; vim.wo.number=false; vim.wo.relativenumber=false; vim.wo.signcolumn='no'; vim.wo.wrap=false
  vim.wo.cursorline=true; vim.wo.cursorlineopt='line'; vim.wo.foldcolumn='0'; vim.wo.colorcolumn=''
  vim.wo.winhighlight='Normal:CoffeSidebarNormal,NormalNC:CoffeSidebarNormal,EndOfBuffer:CoffeSidebarNormal,CursorLine:CoffeSidebarSelection'
  local function map(key,fn) vim.keymap.set('n',key,fn,{buffer=M.buf,nowait=true,silent=true}) end
  map('<CR>',function()
    local entry=current(); if not entry then return end
    if entry.kind=='directory' then M.expanded[entry.path]=not M.expanded[entry.path]; M.refresh() else util.edit(entry.path) end
  end)
  map('q',M.close); map('R',M.refresh)
  map('.',function() M.hidden=not M.hidden; M.refresh() end)
  map('a',function()
    local entry=current()
    local parent=entry and (entry.kind=='directory' and entry.path or vim.fs.dirname(entry.path)) or M.root
    vim.ui.input({prompt='New path (end with / for folder): ',default=parent..'/'},function(path)
      if not path or path=='' then return end
      local folder=path:sub(-1)=='/'
      path=util.path(path)
      if vim.uv.fs_stat(path) then util.notify('Path already exists',vim.log.levels.WARN); return end
      local ok,err=pcall(function()
        vim.fn.mkdir(folder and path or vim.fs.dirname(path),'p')
        if not folder then
          local fd,reason=vim.uv.fs_open(path,'wx',420)
          assert(fd,reason); vim.uv.fs_close(fd)
        end
      end)
      if not ok then util.notify(tostring(err),vim.log.levels.ERROR) end
      M.expanded[parent]=true; M.refresh()
      if ok and not folder then util.edit(path) end
    end)
  end)
  map('r',function()
    local entry=current(); if not entry then return end
    -- Avoid stale paths or lost edits: close loaded files before filesystem rename.
    for _,b in ipairs(vim.api.nvim_list_bufs()) do
      local name=vim.api.nvim_buf_get_name(b)
      if vim.api.nvim_buf_is_loaded(b) and (name==entry.path or name:sub(1,#entry.path+1)==entry.path..'/') then
        util.notify('Close buffers inside this path before renaming (:bdelete).',vim.log.levels.WARN); return
      end
    end
    vim.ui.input({prompt='Rename to: ',default=entry.path},function(path)
      if not path or path=='' or path==entry.path then return end
      path=util.path(path)
      if vim.uv.fs_stat(path) then util.notify('Destination already exists',vim.log.levels.WARN); return end
      local ok,err=vim.uv.fs_rename(entry.path,path)
      if not ok then util.notify(err,vim.log.levels.ERROR) end
      M.refresh()
    end)
  end)
  map('D',function()
    local entry=current(); if not entry then return end
    for _,b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b)==entry.path then util.notify('Close this file first (:bdelete).',vim.log.levels.WARN); return end
    end
    vim.ui.select({'Cancel','Delete'}, {prompt='Permanently delete '..entry.name..'? (folders must be empty)'},function(choice)
      if choice~='Delete' then return end
      local ok,err
      if entry.kind=='directory' then ok,err=vim.uv.fs_rmdir(entry.path) else ok,err=vim.uv.fs_unlink(entry.path) end
      if not ok then util.notify(err,vim.log.levels.ERROR) end
      M.refresh()
    end)
  end)
  M.refresh()
  vim.api.nvim_set_current_win(M.win)
end
function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then M.close() else M.open() end
end
return M
