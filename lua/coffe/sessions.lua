local M = {}
local util = require('coffe.util')

local function file(root)
  root = util.path(root)
  root = vim.uv.fs_realpath(root) or root
  return vim.fn.stdpath('state') .. '/coffe/sessions/' .. vim.fn.sha256(root):sub(1, 24) .. '.json'
end

function M.path(root) return file(root) end

local function read(root)
  local ok, lines = pcall(vim.fn.readfile, file(root))
  if not ok then return nil end
  local valid, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  return valid and type(data) == 'table' and data or nil
end

function M.can_restore()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then return false end
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= '' then return false end
  end
  return true
end

function M.save(root)
  if not require('coffe').config.sessions.enabled then return false end
  root = util.path(root or vim.fn.getcwd())
  root = vim.uv.fs_realpath(root) or root
  local tabs, active_tab = {}, vim.api.nvim_get_current_tabpage()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local windows = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf, path = vim.api.nvim_win_get_buf(win), vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      path = path ~= '' and (vim.uv.fs_realpath(path) or path) or ''
      local relative = path ~= '' and vim.fs.relpath(root, path) or nil
      if relative and vim.bo[buf].buftype == '' and vim.fn.filereadable(path) == 1 then
        windows[#windows + 1] = {
          path = path, cursor = vim.api.nvim_win_get_cursor(win), current = win == vim.api.nvim_get_current_win(),
        }
      end
    end
    if #windows > 0 then
      tabs[#tabs + 1] = { windows = windows, current = tab == active_tab }
    end
  end
  if #tabs == 0 then return false end
  local target = file(root); vim.fn.mkdir(vim.fn.fnamemodify(target, ':h'), 'p')
  local temporary = target .. '.tmp'
  local ok = pcall(vim.fn.writefile, { vim.json.encode({ root = root, tabs = tabs }) }, temporary)
  if not ok or not vim.uv.fs_rename(temporary, target) then pcall(vim.fn.delete, temporary); return false end
  return true
end

function M.restore(root)
  if not require('coffe').config.sessions.enabled or not M.can_restore() then return false end
  local data = read(root)
  if not data then return false end
  local tabs = data.tabs
  if type(tabs) ~= 'table' and type(data.buffers) == 'table' then tabs = { { windows = data.buffers, current = true } } end
  if type(tabs) ~= 'table' then return false end
  local restored, focus
  for _, tab in ipairs(tabs) do
    local valid = vim.tbl_filter(function(item)
      return type(item) == 'table' and type(item.path) == 'string' and vim.fn.filereadable(item.path) == 1
    end, type(tab.windows) == 'table' and tab.windows or {})
    if #valid > 0 then
      if restored then vim.cmd.tabnew() end
      for index, item in ipairs(valid) do
        if index > 1 then vim.cmd.vsplit() end
        util.edit(item.path)
        if type(item.cursor) == 'table' then pcall(vim.api.nvim_win_set_cursor, 0, item.cursor) end
        if tab.current and item.current then focus = vim.api.nvim_get_current_win() end
      end
      restored = true
    end
  end
  if focus and vim.api.nvim_win_is_valid(focus) then vim.api.nvim_set_current_win(focus) end
  if not restored then return false end
  return true
end

function M.setup()
  local group = vim.api.nvim_create_augroup('CoffeSessions', { clear = true })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = function() M.save(vim.fn.getcwd()) end })
end

return M
