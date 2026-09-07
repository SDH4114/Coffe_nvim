local M = {}
local util = require('coffe.util')
local ui = require('coffe.ui')
local ns = vim.api.nvim_create_namespace('coffe_picker')

local function fuzzy_score(text, query)
  text, query = text:lower(), query:lower()
  if query == '' then return 0 end
  local exact = text:find(query, 1, true)
  if exact then return exact - 1 end
  local position, score = 1, 100
  for char in query:gmatch('.') do
    local found = text:find(char, position, true)
    if not found then return nil end
    score = score + found - position
    position = found + 1
  end
  return score
end

-- Dependency-free fuzzy picker. It starts in insert mode but retains normal-mode
-- character mappings so it remains usable in macros and headless tests.
function M.open(title, items, accept, opts)
  opts = opts or {}
  local origin = vim.api.nvim_get_current_win()
  local height = math.max(5, math.min(opts.height or 18, vim.o.lines - 6))
  local buf, win = ui.float({
    filetype = 'coffe_picker', title = title,
    footer = opts.footer or 'type filter · ↑/↓ select · Enter open · Esc close',
    width = opts.width or math.min(90, vim.o.columns - 4), height = height, cursorline = true,
  })
  local query, selected, filtered, first = '', 1, {}, 1

  local function close()
    if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then vim.cmd.stopinsert() end
    ui.close(win, origin)
  end
  local function label(item) return item.label or tostring(item) end
  local function render()
    if not vim.api.nvim_win_is_valid(win) then return end
    filtered = {}
    for index, item in ipairs(items) do
      local score = fuzzy_score(label(item), query)
      if score then filtered[#filtered + 1] = { item = item, score = score, index = index } end
    end
    table.sort(filtered, function(a, b)
      if a.score == b.score then return a.index < b.index end
      return a.score < b.score
    end)
    selected = math.max(1, math.min(selected, math.max(1, #filtered)))
    local visible = height - 2
    if selected < first then first = selected end
    if selected >= first + visible then first = selected - visible + 1 end
    local lines = { string.format('  > %s  ·  %d result%s', query, #filtered, #filtered == 1 and '' or 's'), '' }
    for index = first, math.min(#filtered, first + visible - 1) do
      local prefix = index == selected and '› ' or '  '
      lines[#lines + 1] = prefix .. label(filtered[index].item)
    end
    if #filtered == 0 then lines[3] = opts.empty or '  No matches' end
    util.lines(buf, lines)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 2, { end_col = #lines[1], hl_group = 'CoffeUIKey' })
    local row = #filtered > 0 and math.min(#lines, selected - first + 3) or 1
    vim.api.nvim_win_set_cursor(win, { row, 0 })
  end
  local function move(delta)
    if #filtered == 0 then return end
    selected = ((selected - 1 + delta) % #filtered) + 1
    render()
  end
  local function chosen() return filtered[selected] and filtered[selected].item end
  local function submit()
    local item = chosen()
    close()
    if item then accept(item) end
  end
  local function append(char) query = query .. char; selected, first = 1, 1; render(); return '' end
  local function backspace()
    query = vim.fn.strcharpart(query, 0, math.max(0, vim.fn.strchars(query) - 1))
    selected, first = 1, 1; render(); return ''
  end
  local function map(modes, key, fn, extra)
    local options = vim.tbl_extend('force', { buffer = buf, nowait = true, silent = true }, extra or {})
    vim.keymap.set(modes, key, fn, options)
  end
  map({ 'n', 'i' }, '<Esc>', close); map({ 'n', 'i' }, '<C-c>', close)
  map({ 'n', 'i' }, '<CR>', submit)
  for _, key in ipairs({ '<Down>', '<C-n>' }) do map({ 'n', 'i' }, key, function() move(1) end) end
  for _, key in ipairs({ '<Up>', '<C-p>' }) do map({ 'n', 'i' }, key, function() move(-1) end) end
  map({ 'n', 'i' }, '<BS>', backspace)
  map({ 'n', 'i' }, '<C-u>', function() query = ''; selected, first = 1, 1; render() end)
  map({ 'n', 'i' }, '<C-f>', function()
    vim.ui.input({ prompt = 'Filter: ', default = query }, function(value)
      if value and vim.api.nvim_win_is_valid(win) then query = value; selected, first = 1, 1; render() end
    end)
  end)
  map({ 'n', 'i' }, '<D-v>', function()
    local register = vim.fn.has('clipboard') == 1 and '+' or '"'
    query = query .. vim.fn.getreg(register):gsub('[\r\n]+', ' ')
    selected, first = 1, 1; render()
  end)
  if opts.on_delete then
    map({ 'n', 'i' }, '<C-x>', function()
      local item = chosen()
      if item and opts.on_delete(item) ~= false then
        for index, candidate in ipairs(items) do if candidate == item then table.remove(items, index); break end end
        selected = math.min(selected, math.max(1, #items)); render()
      end
    end)
  end
  if opts.on_preview then map({ 'n', 'i' }, '<C-o>', function() local item = chosen(); if item then opts.on_preview(item) end end) end
  for key, action in pairs(opts.actions or {}) do
    map({ 'n', 'i' }, key, function() local item = chosen(); if item then action(item); render() end end)
  end
  for byte = 32, 126 do
    local char = string.char(byte)
    local key = char == '<' and '<lt>' or char
    map('n', key, function() append(char) end)
    map('i', key, function() append(char) end)
  end
  render()
  vim.schedule(function() if vim.api.nvim_win_is_valid(win) then vim.cmd.startinsert() end end)
  return { buf = buf, win = win, close = close, render = render }
end

local function choose_files(paths, title)
  local items = {}
  for _, path in ipairs(paths) do
    items[#items + 1] = { label = vim.fn.fnamemodify(path, ':~:.'), path = path }
  end
  M.open(title, items, function(item) util.edit(item.path) end, {
    on_preview = function(item) ui.preview(item.path) end,
    footer = 'type filter · Enter open · Ctrl-O preview · Esc close',
  })
end

function M.files()
  local root = vim.fn.getcwd()
  if vim.fn.executable('rg') == 1 then
    vim.system({ 'rg', '--files', '--hidden', '-g', '!.git' }, { cwd = root, text = true }, function(result)
      vim.schedule(function()
        if result.code > 1 then util.notify(result.stderr, vim.log.levels.ERROR); return end
        local items = {}
        for line in (result.stdout or ''):gmatch('[^\n]+') do items[#items + 1] = { label = line, path = root .. '/' .. line } end
        M.open('Find files', items, function(item) util.edit(item.path) end, {
          empty = '  No files found', on_preview = function(item) ui.preview(item.path) end,
          footer = 'type filter · Enter open · Ctrl-O preview · Esc close',
        })
      end)
    end)
  else
    local files = {}
    local function scan(dir, depth)
      if depth > 20 or #files >= 10000 then return end
      local ok = pcall(function()
        for name, kind in vim.fs.dir(dir) do
          if name:sub(1, 1) ~= '.' and name ~= 'node_modules' then
            local path = dir .. '/' .. name
            if kind == 'directory' then scan(path, depth + 1) elseif kind == 'file' then files[#files + 1] = path end
          end
          if #files >= 10000 then break end
        end
      end)
      if not ok then return end
    end
    scan(root, 0); choose_files(files, 'Find files')
  end
end

function M.grep()
  if vim.fn.executable('rg') ~= 1 then
    util.notify('Install ripgrep to search file contents: brew install ripgrep', vim.log.levels.WARN); return
  end
  vim.ui.input({ prompt = 'Search text (literal): ' }, function(query)
    if not query or query == '' then return end
    local root = vim.fn.getcwd()
    vim.system({ 'rg', '--json', '--fixed-strings', '--smart-case', '--', query, '.' }, { cwd = root, text = true }, function(result)
      vim.schedule(function()
        if result.code > 1 then util.notify(result.stderr, vim.log.levels.ERROR); return end
        local items = {}
        for line in (result.stdout or ''):gmatch('[^\n]+') do
          local ok, record = pcall(vim.json.decode, line)
          if ok and record.type == 'match' and record.data.path.text and record.data.lines.text then
            local d = record.data
            items[#items + 1] = {
              label = d.path.text .. ':' .. d.line_number .. ' ' .. d.lines.text:gsub('%s+$', ''),
              path = root .. '/' .. d.path.text, line = d.line_number,
            }
          end
        end
        M.open('Search: ' .. query, items, function(item)
          util.edit(item.path)
          if vim.api.nvim_buf_get_name(0) == vim.fs.normalize(item.path) then vim.api.nvim_win_set_cursor(0, { item.line, 0 }) end
        end, { empty = '  No text matches', on_preview = function(item) ui.preview(item.path, item.line) end,
          footer = 'type filter · Enter open · Ctrl-O preview · Esc close' })
      end)
    end)
  end)
end

function M.recent()
  choose_files(vim.tbl_filter(function(path) return vim.fn.filereadable(path) == 1 end, vim.v.oldfiles), 'Recent files')
end

function M.buffers()
  local items = {}
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].buflisted then
      local name = vim.api.nvim_buf_get_name(buffer)
      items[#items + 1] = {
        label = (vim.bo[buffer].modified and '[+] ' or '    ') .. (name ~= '' and vim.fn.fnamemodify(name, ':~:.') or '[No name]'),
        buf = buffer, path = name,
      }
    end
  end
  M.open('Buffers', items, function(item) if vim.api.nvim_buf_is_valid(item.buf) then vim.api.nvim_set_current_buf(item.buf) end end, {
    empty = '  No open buffers', footer = 'type filter · Enter switch · Ctrl-X close · Esc close',
    on_delete = function(item)
      if vim.bo[item.buf].modified then util.notify('Save or discard changes before closing this buffer.', vim.log.levels.WARN); return false end
      return pcall(vim.api.nvim_buf_delete, item.buf, {})
    end,
    on_preview = function(item) if item.path ~= '' then ui.preview(item.path) end end,
  })
end

return M
