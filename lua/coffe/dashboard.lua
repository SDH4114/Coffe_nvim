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

local compact_logo = {
  '╭──────────────────╮',
  '│  C  O  F  F  E  │',
  '╰──────────────────╯',
}

local function center(text, width)
  local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
  return string.rep(' ', padding) .. text, padding
end

local function highlights()
  vim.api.nvim_set_hl(0, 'CoffeDashboardLogo', { link = 'Title', default = true })
  vim.api.nvim_set_hl(0, 'CoffeDashboardTagline', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'CoffeDashboardButton', { link = 'Normal', default = true })
  vim.api.nvim_set_hl(0, 'CoffeDashboardButtonActive', { link = 'Visual', default = true })
  vim.api.nvim_set_hl(0, 'CoffeDashboardKey', { link = 'Special', default = true })
  vim.api.nvim_set_hl(0, 'CoffeDashboardPath', { link = 'Directory', default = true })
end

function M.open()
  -- Opening home must never replace unsaved work.
  if vim.bo.modified then vim.cmd('new') end

  local buf = util.scratch('coffe')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buflisted = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].colorcolumn = ''
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false
  vim.wo[win].spell = false

  local actions = require('coffe.actions')
  local projects = require('coffe.projects')
  local buttons = {
    { key = 'n', label = 'New project', run = projects.create },
    { key = 'o', label = 'Open project', run = projects.prompt_open },
    { key = 'r', label = 'Recent projects', run = projects.pick },
    { key = 'f', label = 'Find files', run = actions.files },
    { key = 'g', label = 'Search in files', run = actions.search },
    { key = 'e', label = 'File explorer', run = actions.explorer },
    { key = ',', label = 'Settings', run = actions.settings },
    { key = '?', label = 'Keyboard guide', run = function() vim.cmd.CoffeKeys() end },
    { key = 'q', label = 'Quit', run = function() vim.cmd.quit() end },
  }

  local selected = 1
  local button_rows = {}
  local button_columns = {}
  local button_lengths = {}

  local function paint()
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then return end
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    highlights()
    for index, row in ipairs(button_rows) do
      local column = button_columns[index]
      local group = index == selected and 'CoffeDashboardButtonActive' or 'CoffeDashboardButton'
      vim.api.nvim_buf_set_extmark(buf, ns, row - 1, column, {
        end_col = column + button_lengths[index],
        hl_group = group,
      })
      vim.api.nvim_buf_set_extmark(buf, ns, row - 1, column + 2, {
        end_col = column + 7,
        hl_group = 'CoffeDashboardKey',
        priority = 110,
      })
    end
  end

  local function render()
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then return end
    local width = vim.api.nvim_win_get_width(win)
    local height = vim.api.nvim_win_get_height(win)
    local active_logo = width >= 54 and logo or compact_logo
    local content_height = #active_logo + #buttons + 6
    local top = math.max(1, math.floor((height - content_height) / 2))
    local lines = {}
    local marks = {}
    button_rows, button_columns, button_lengths = {}, {}, {}

    for _ = 1, top do lines[#lines + 1] = '' end
    for _, line in ipairs(active_logo) do
      local centered, column = center(line, width)
      lines[#lines + 1] = centered
      marks[#marks + 1] = { row = #lines, column = column, length = #line, group = 'CoffeDashboardLogo' }
    end

    lines[#lines + 1] = ''
    local tagline = 'A focused place to build'
    local centered, column = center(tagline, width)
    lines[#lines + 1] = centered
    marks[#marks + 1] = { row = #lines, column = column, length = #tagline, group = 'CoffeDashboardTagline' }
    lines[#lines + 1] = ''

    for _, button in ipairs(buttons) do
      local text = string.format('  [ %s ]  %-21s', button.key:upper(), button.label)
      local button_line, button_column = center(text, width)
      lines[#lines + 1] = button_line
      button_rows[#button_rows + 1] = #lines
      button_columns[#button_columns + 1] = button_column
      button_lengths[#button_lengths + 1] = #text
    end

    lines[#lines + 1] = ''
    local path = vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
    local path_line, path_column = center(path, width)
    lines[#lines + 1] = path_line
    marks[#marks + 1] = { row = #lines, column = path_column, length = #path, group = 'CoffeDashboardPath' }

    util.lines(buf, lines)
    for _, mark in ipairs(marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, mark.row - 1, mark.column, {
        end_col = mark.column + mark.length,
        hl_group = mark.group,
      })
    end
    paint()
    vim.api.nvim_win_set_cursor(win, { button_rows[selected], button_columns[selected] + 2 })
  end

  local function select(index)
    selected = ((index - 1) % #buttons) + 1
    paint()
    vim.api.nvim_win_set_cursor(win, { button_rows[selected], button_columns[selected] + 2 })
  end

  local function run_selected()
    buttons[selected].run()
  end

  for index, button in ipairs(buttons) do
    local target = index
    local action = button.run
    for _, key in ipairs({ button.key, button.key:upper() }) do
      vim.keymap.set('n', key, action, { buffer = buf, nowait = true, silent = true })
    end
    vim.keymap.set('n', tostring(target), function() select(target) end, {
      buffer = buf,
      nowait = true,
      silent = true,
      desc = 'Coffe: select dashboard action ' .. target,
    })
  end
  vim.keymap.set('n', '<CR>', run_selected, { buffer = buf, silent = true })
  for _, key in ipairs({ 'j', '<Down>', '<Tab>' }) do
    vim.keymap.set('n', key, function() select(selected + 1) end, { buffer = buf, silent = true })
  end
  for _, key in ipairs({ 'k', '<Up>', '<S-Tab>' }) do
    vim.keymap.set('n', key, function() select(selected - 1) end, { buffer = buf, silent = true })
  end
  vim.keymap.set('n', 'gg', function() select(1) end, { buffer = buf, silent = true })
  vim.keymap.set('n', 'G', function() select(#buttons) end, { buffer = buf, silent = true })

  local group = vim.api.nvim_create_augroup('CoffeDashboard' .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = group,
    callback = render,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    buffer = buf,
    once = true,
    callback = function() pcall(vim.api.nvim_del_augroup_by_id, group) end,
  })

  render()
end

return M
