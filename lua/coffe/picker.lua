local M = {}
local util = require('coffe.util')
local ns = vim.api.nvim_create_namespace('coffe_picker')
local function highlights()
  vim.api.nvim_set_hl(0, 'CoffePickerNormal', { link = 'NormalFloat', default = true })
  vim.api.nvim_set_hl(0, 'CoffePickerBorder', { link = 'FloatBorder', default = true })
  vim.api.nvim_set_hl(0, 'CoffePickerTitle', { link = 'Title', default = true })
  vim.api.nvim_set_hl(0, 'CoffePickerPrompt', { link = 'Special', default = true })
  vim.api.nvim_set_hl(0, 'CoffePickerSelection', { link = 'Visual', default = true })
end
-- A small keyboard-first picker. No external UI plugin required.
function M.open(title, items, accept)
  highlights()
  local origin = vim.api.nvim_get_current_win()
  local buf = util.scratch('coffe_picker')
  local width = math.max(20, math.min(90, vim.o.columns - 4))
  local height = math.max(3, math.min(18, vim.o.lines - 6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative='editor', row=math.max(0, math.floor((vim.o.lines-height)/2)-1), col=math.max(0, math.floor((vim.o.columns-width)/2)),
    width=width, height=height, style='minimal', border='rounded', title=' '..title..' ', title_pos='center',
    footer=' type to filter · Enter open · Esc close ', footer_pos='center',
  })
  vim.wo[win].cursorline = true
  vim.wo[win].cursorlineopt = 'line'
  vim.wo[win].wrap = false
  vim.wo[win].winblend = 0
  vim.wo[win].winhighlight = 'NormalFloat:CoffePickerNormal,FloatBorder:CoffePickerBorder,FloatTitle:CoffePickerTitle,CursorLine:CoffePickerSelection'
  local query, selected, filtered = '', 1, {}
  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if vim.api.nvim_win_is_valid(origin) then vim.api.nvim_set_current_win(origin) end
  end
  local function render()
    filtered = {}
    for _, item in ipairs(items) do
      if (item.label or tostring(item)):lower():find(query:lower(), 1, true) then filtered[#filtered+1] = item end
    end
    selected = math.max(1, math.min(selected, #filtered))
    local lines = { '  > '..query..'  ·  '..#filtered..' results', '' }
    local first = math.max(1, selected-height+3)
    for i=first, math.min(#filtered, first+height-3) do
      lines[#lines+1] = (i==selected and '› ' or '  ')..(filtered[i].label or tostring(filtered[i]))
    end
    if #filtered == 0 then lines[3] = '  No matches' end
    util.lines(buf, lines)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 2, { end_col = #lines[1], hl_group = 'CoffePickerPrompt' })
    vim.api.nvim_win_set_cursor(win, { math.min(#lines, selected-first+3), 0 })
  end
  local function map(key, fn) vim.keymap.set('n', key, fn, { buffer=buf, nowait=true, silent=true }) end
  map('<Esc>', close); map('<C-c>', close)
  map('<CR>', function() local item=filtered[selected]; close(); if item then accept(item) end end)
  for _, key in ipairs({'<Down>', '<C-n>'}) do map(key, function() selected=selected+1; render() end) end
  for _, key in ipairs({'<Up>', '<C-p>'}) do map(key, function() selected=selected-1; render() end) end
  map('<BS>', function() query=vim.fn.strcharpart(query,0,math.max(0,vim.fn.strchars(query)-1)); selected=1; render() end)
  map('<C-u>', function() query=''; selected=1; render() end)
  map('<C-f>', function()
    vim.ui.input({prompt='Filter: ', default=query}, function(value)
      if value and vim.api.nvim_win_is_valid(win) then query=value; selected=1; render() end
    end)
  end)
  for byte=32,126 do
    local char=string.char(byte)
    map(char=='<' and '<lt>' or char, function() query=query..char; selected=1; render() end)
  end
  render()
  return { buf=buf, win=win, close=close }
end
local function choose_files(paths, title)
  local items={}
  for _, path in ipairs(paths) do items[#items+1]={label=path, path=path} end
  M.open(title, items, function(item) util.edit(item.path) end)
end
function M.files()
  local root=vim.fn.getcwd()
  if vim.fn.executable('rg') == 1 then
    vim.system({'rg','--files','--hidden','-g','!.git'}, {cwd=root, text=true}, function(result)
      vim.schedule(function()
        if result.code > 1 then util.notify(result.stderr, vim.log.levels.ERROR); return end
        local items={}
        for line in (result.stdout or ''):gmatch('[^\n]+') do items[#items+1]={label=line,path=root..'/'..line} end
        M.open('Find files', items, function(item) util.edit(item.path) end)
      end)
    end)
  else
    local files={}
    local function scan(dir, depth)
      if depth > 20 or #files >= 10000 then return end
      for name, kind in vim.fs.dir(dir) do
        if name:sub(1,1) ~= '.' and name ~= 'node_modules' then
          local path=dir..'/'..name
          if kind=='directory' then scan(path,depth+1) elseif kind=='file' then files[#files+1]=path end
        end
        if #files >= 10000 then break end
      end
    end
    scan(root,0); choose_files(files,'Find files')
  end
end
function M.grep()
  if vim.fn.executable('rg') ~= 1 then util.notify('Install ripgrep to search file contents: brew install ripgrep', vim.log.levels.WARN); return end
  vim.ui.input({prompt='Search text (literal): '}, function(query)
    if not query or query=='' then return end
    local root=vim.fn.getcwd()
    vim.system({'rg','--json','--fixed-strings','--smart-case','--',query,'.'}, {cwd=root,text=true}, function(result)
      vim.schedule(function()
        if result.code > 1 then util.notify(result.stderr,vim.log.levels.ERROR); return end
        local items={}
        for line in (result.stdout or ''):gmatch('[^\n]+') do
          local ok, record=pcall(vim.json.decode,line)
          if ok and record.type=='match' and record.data.path.text and record.data.lines.text then
            local d=record.data
            items[#items+1]={label=d.path.text..':'..d.line_number..' '..d.lines.text:gsub('%s+$',''),path=root..'/'..d.path.text,line=d.line_number}
          end
        end
        M.open('Search: '..query,items,function(item)
          util.edit(item.path)
          if vim.api.nvim_buf_get_name(0)==vim.fs.normalize(item.path) then vim.api.nvim_win_set_cursor(0,{item.line,0}) end
        end)
      end)
    end)
  end)
end
function M.recent()
  local paths={}
  for _, path in ipairs(vim.v.oldfiles) do if vim.fn.filereadable(path)==1 then paths[#paths+1]=path end end
  choose_files(paths,'Recent files')
end
function M.buffers()
  local items={}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted then items[#items+1]={label=vim.api.nvim_buf_get_name(b)~='' and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b),':~:.') or '[No name]',buf=b} end
  end
  M.open('Buffers',items,function(item) vim.api.nvim_set_current_buf(item.buf) end)
end
return M
