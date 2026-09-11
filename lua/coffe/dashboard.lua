local M = {}
local util = require('coffe.util')
local ns = vim.api.nvim_create_namespace('coffe_dashboard')

local logo = {
  ' ██████╗ ██████╗ ███████╗███████╗███████╗',
  '██╔════╝██╔═══██╗██╔════╝██╔════╝██╔════╝',
  '██║     ██║   ██║█████╗  █████╗  █████╗  ',
  '██║     ██║   ██║██╔══╝  ██╔══╝  ██╔══╝  ',
  '╚██████╗╚██████╔╝██║     ██║     ███████╗',
  ' ╚═════╝ ╚═════╝ ╚═╝     ╚═╝     ╚══════╝',
}
local compact_logo = { '╭──────────────────╮', '│  C  O  F  F  E  │', '╰──────────────────╯' }

local function center(text, width)
  local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
  return string.rep(' ', padding) .. text, padding
end

local function highlights()
  local groups = {
    CoffeDashboardLogo = 'Title', CoffeDashboardTagline = 'Comment', CoffeDashboardSection = 'Function',
    CoffeDashboardButton = 'Normal', CoffeDashboardButtonActive = 'Visual', CoffeDashboardKey = 'Special',
    CoffeDashboardPath = 'Directory', CoffeDashboardMuted = 'Comment', CoffeDashboardPinned = 'DiagnosticWarn',
  }
  for name, link in pairs(groups) do vim.api.nvim_set_hl(0, name, { link = link, default = true }) end
end

local function git_branch(path)
  local result = vim.system({ 'git', '-C', path, 'branch', '--show-current' }, { text = true }):wait()
  local branch = result.code == 0 and vim.trim(result.stdout or '') or ''
  return branch ~= '' and branch or nil
end

function M.open()
  if vim.bo.modified then vim.cmd('new') end
  local buf = util.scratch('coffe')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buflisted = false
  for option, value in pairs({ number = false, relativenumber = false, signcolumn = 'no', foldcolumn = '0',
    colorcolumn = '', cursorline = false, wrap = false, spell = false }) do vim.wo[win][option] = value end

  local actions, projects = require('coffe.actions'), require('coffe.projects')
  local entries, selected, rows, row_to_index = {}, 1, {}, {}
  local marks = {}

  local function build_entries()
    entries = {
      { section = 'QUICK ACTIONS' },
      { key = 'n', label = 'New project', detail = 'create a workspace', run = projects.create },
      { key = 'o', label = 'Open project', detail = 'choose a folder', run = projects.prompt_open },
      { key = 'f', label = 'Find files', detail = 'search by name', run = actions.files },
      { key = 'g', label = 'Search text', detail = 'search project contents', run = actions.search },
      { key = 'b', label = 'Buffers', detail = 'switch or close', run = actions.buffers },
      { key = 'e', label = 'Explorer', detail = 'browse project files', run = actions.explorer },
      { key = 'i', label = 'Quick note', detail = 'capture an idea', run = actions.note },
      { key = 'v', label = 'Git status', detail = 'review changes', run = actions.git },
      { key = 'c', label = 'Commands', detail = 'all Coffe actions', run = actions.palette },
      { key = '?', label = 'Keyboard guide', detail = 'shortcuts and help', run = function() vim.cmd.CfKeys() end },
    }
    local pinned = projects.pinned()
    local recent = projects.recent()
    if #pinned > 0 then
      entries[#entries + 1] = { section = 'PINNED PROJECTS' }
      for index = 1, math.min(3, #pinned) do
        local path = pinned[index]
        entries[#entries + 1] = { label = '★ ' .. vim.fn.fnamemodify(path, ':t'), detail = vim.fn.fnamemodify(path, ':~'),
          run = function() projects.open(path) end, group = 'CoffeDashboardPinned' }
      end
    elseif #recent > 0 then
      entries[#entries + 1] = { section = 'RECENT PROJECTS' }
      for index = 1, math.min(3, #recent) do
        local path = recent[index]
        entries[#entries + 1] = { label = vim.fn.fnamemodify(path, ':t'), detail = vim.fn.fnamemodify(path, ':~'),
          run = function() projects.open(path) end }
      end
    end
    local oldfiles, count = {}, 0
    for _, path in ipairs(vim.v.oldfiles) do
      if vim.fn.filereadable(path) == 1 then
        oldfiles[#oldfiles + 1] = path; count = count + 1
        if count == 3 then break end
      end
    end
    if #oldfiles > 0 then
      entries[#entries + 1] = { section = 'RECENT FILES' }
      for _, path in ipairs(oldfiles) do
        entries[#entries + 1] = { label = vim.fn.fnamemodify(path, ':t'), detail = vim.fn.fnamemodify(path, ':~:.'),
          run = function() util.edit(path) end }
      end
    end
  end

  local function selectable(index)
    while index < 1 do index = #entries end
    while index > #entries do index = 1 end
    while entries[index].section do index = index == #entries and 1 or index + 1 end
    return index
  end

  local function paint()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    highlights()
    for _, mark in ipairs(marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, mark.row - 1, mark.col, {
        end_col = mark.col + mark.length, hl_group = mark.group, priority = mark.priority,
      })
    end
    for index, row in pairs(rows) do
      local entry = entries[index]
      local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ''
      vim.api.nvim_buf_set_extmark(buf, ns, row - 1, 0, {
        end_col = #line, hl_eol = true,
        hl_group = index == selected and 'CoffeDashboardButtonActive' or (entry.group or 'CoffeDashboardButton'),
      })
    end
  end

  local function render()
    if not vim.api.nvim_win_is_valid(win) then return end
    build_entries(); selected = selectable(math.min(selected, #entries))
    local width, height = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
    local active_logo = width >= 54 and height >= 25 and logo or compact_logo
    local lines = {}; marks = {}; rows = {}; row_to_index = {}
    local content_height = #active_logo + #entries + 7
    for _ = 1, math.max(0, math.floor((height - content_height) / 2)) do lines[#lines + 1] = '' end
    for _, line in ipairs(active_logo) do
      local text, col = center(line, width); lines[#lines + 1] = text
      marks[#marks + 1] = { row = #lines, col = col, length = #line, group = 'CoffeDashboardLogo' }
    end
    lines[#lines + 1] = ''
    local tagline = 'A focused place to build'
    local text, col = center(tagline, width); lines[#lines + 1] = text
    marks[#marks + 1] = { row = #lines, col = col, length = #tagline, group = 'CoffeDashboardTagline' }
    lines[#lines + 1] = ''
    local menu_width = math.min(64, math.max(28, width - 4))
    local left = math.max(0, math.floor((width - menu_width) / 2))
    for index, entry in ipairs(entries) do
      if entry.section then
        if index > 1 then lines[#lines + 1] = '' end
        lines[#lines + 1] = string.rep(' ', left) .. entry.section
        marks[#marks + 1] = { row = #lines, col = left, length = #entry.section, group = 'CoffeDashboardSection' }
      else
        local key = entry.key and ('[' .. entry.key:upper() .. '] ') or '    '
        local available = math.max(0, menu_width - vim.fn.strdisplaywidth(key) - vim.fn.strdisplaywidth(entry.label) - 3)
        local detail = width >= 62 and entry.detail or ''
        if vim.fn.strdisplaywidth(detail) > available then detail = vim.fn.strcharpart(detail, 0, math.max(0, available - 1)) .. '…' end
        local gap = string.rep(' ', math.max(1, menu_width - vim.fn.strdisplaywidth(key .. entry.label .. detail)))
        lines[#lines + 1] = string.rep(' ', left) .. key .. entry.label .. gap .. detail
        rows[index], row_to_index[#lines] = #lines, index
        if entry.key then marks[#marks + 1] = { row = #lines, col = left, length = #key - 1, group = 'CoffeDashboardKey', priority = 110 } end
        if detail ~= '' then marks[#marks + 1] = { row = #lines, col = left + #key + #entry.label + #gap, length = #detail, group = 'CoffeDashboardMuted', priority = 110 } end
      end
    end
    lines[#lines + 1] = ''
    local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
    local branch = git_branch(vim.fn.getcwd())
    local context = branch and (cwd .. '  ·  git:' .. branch) or cwd
    text, col = center(context, width); lines[#lines + 1] = text
    marks[#marks + 1] = { row = #lines, col = col, length = #context, group = 'CoffeDashboardPath' }
    lines[#lines + 1] = center('j/k navigate · Enter open · c commands · q quit', width)
    marks[#marks + 1] = { row = #lines, col = math.max(0, math.floor((width - 47) / 2)), length = 47, group = 'CoffeDashboardMuted' }
    util.lines(buf, lines); paint()
    local row = rows[selected]
    if row then vim.api.nvim_win_set_cursor(win, { row, 0 }) end
  end

  local function select(index)
    selected = selectable(index); paint()
    if rows[selected] then vim.api.nvim_win_set_cursor(win, { rows[selected], 0 }) end
  end
  local function run_selected() if entries[selected] and entries[selected].run then entries[selected].run() end end
  local function map(key, fn) vim.keymap.set('n', key, fn, { buffer = buf, nowait = true, silent = true }) end
  for _, key in ipairs({ 'j', '<Down>', '<Tab>' }) do map(key, function() select(selected + 1) end) end
  for _, key in ipairs({ 'k', '<Up>', '<S-Tab>' }) do map(key, function() select(selected - 1) end) end
  map('<CR>', run_selected); map('gg', function() select(1) end); map('G', function() select(#entries) end)
  map('q', function() vim.cmd.quit() end)
  for _, pair in ipairs({ { 'n', projects.create }, { 'o', projects.prompt_open }, { 'f', actions.files },
    { 'g', actions.search }, { 'b', actions.buffers }, { 'e', actions.explorer }, { 'i', actions.note },
    { 'v', actions.git }, { 'c', actions.palette }, { '?', function() vim.cmd.CfKeys() end } }) do
    map(pair[1], pair[2]); map(pair[1]:upper(), pair[2])
  end
  map('<LeftMouse>', function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == win and row_to_index[mouse.line] then select(row_to_index[mouse.line]); run_selected() end
  end)

  local group = vim.api.nvim_create_augroup('CoffeDashboard' .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, { group = group, callback = render })
  vim.api.nvim_create_autocmd('BufWipeout', { group = group, buffer = buf, once = true,
    callback = function() pcall(vim.api.nvim_del_augroup_by_id, group) end })
  render()
end

return M
