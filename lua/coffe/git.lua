local M = {}
local util = require('coffe.util')

local function run(args, cwd)
  if vim.fn.executable('git') ~= 1 then return nil, 'Git is not installed.' end
  local command = { 'git', '-C', cwd }; vim.list_extend(command, args)
  local result = vim.system(command, { text = false }):wait()
  if result.code ~= 0 then return nil, vim.trim(result.stderr or 'Git command failed.') end
  return result.stdout or ''
end

function M.root(path)
  local output = run({ 'rev-parse', '--show-toplevel' }, path or vim.fn.getcwd())
  return output and vim.trim(output) or nil
end

function M.status_sync(path)
  local root = M.root(path); if not root then return {} end
  local output = run({ 'status', '--porcelain=v1', '-z', '--untracked-files=all' }, root)
  if not output then return {} end
  local records = {}; for record in output:gmatch('[^%z]+') do records[#records + 1] = record end
  local items, index = {}, 1
  while index <= #records do
    local record, x, y = records[index], records[index]:sub(1, 1), records[index]:sub(2, 2)
    local path_name = record:sub(4)
    local renamed = x == 'R' or x == 'C' or y == 'R' or y == 'C'
    items[#items + 1] = {
      path = path_name, absolute = root .. '/' .. path_name, x = x, y = y,
      staged = x ~= ' ' and x ~= '?', unstaged = y ~= ' ', untracked = x == '?' and y == '?', renamed = renamed,
    }
    if renamed then index = index + 1 end
    index = index + 1
  end
  return items
end

function M.status(callback, path)
  vim.schedule(function() callback(M.status_sync(path)) end)
end

function M.diff_sync(root, path, staged)
  root = M.root(root) or root
  local args = { 'diff', '--no-ext-diff', '--no-color' }
  if staged then table.insert(args, '--cached') end
  if path then vim.list_extend(args, { '--', path }) end
  return run(args, root) or ''
end

local function show_diff(title, lines)
  if lines == '' then return util.notify('No Git diff to show.', vim.log.levels.INFO) end
  vim.cmd('botright new')
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = 'nofile', 'wipe', false
  vim.bo[buf].filetype = 'diff'; vim.api.nvim_buf_set_name(buf, title)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(lines, '\n', { plain = true }))
  vim.bo[buf].modifiable, vim.bo[buf].modified = false, false
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, silent = true })
end

function M.open_diff(path)
  local root = M.root(); if not root then return util.notify('Not inside a Git repository.', vim.log.levels.WARN) end
  path = path or vim.api.nvim_buf_get_name(0)
  if path == '' then return util.notify('Current buffer has no file.', vim.log.levels.WARN) end
  local relative = vim.fs.relpath(root, path) or path
  local unstaged = M.diff_sync(root, relative, false)
  local staged = M.diff_sync(root, relative, true)
  show_diff('Coffe diff · ' .. relative, staged .. (staged ~= '' and unstaged ~= '' and '\n' or '') .. unstaged)
end

function M.open_diff_all()
  local root = M.root(); if not root then return util.notify('Not inside a Git repository.', vim.log.levels.WARN) end
  local staged, unstaged = M.diff_sync(root, nil, true), M.diff_sync(root, nil, false)
  local output = (staged ~= '' and ('# STAGED\n' .. staged) or '') ..
    (staged ~= '' and unstaged ~= '' and '\n# UNSTAGED\n' or '') .. unstaged
  show_diff('Coffe diff · repository', output)
end

function M.open_status()
  local root = M.root(); if not root then return util.notify('Not inside a Git repository.', vim.log.levels.WARN) end
  local items = M.status_sync(root)
  if #items == 0 then return util.notify('Git working tree is clean.', vim.log.levels.INFO) end
  for _, item in ipairs(items) do
    local state = item.untracked and '??' or (item.x .. item.y)
    item.label = state .. '  ' .. item.path
  end
  require('coffe.picker').open('Git status', items, function(item) util.edit(item.absolute) end, {
    footer = 'type filter · Enter open · Ctrl-O diff · Esc close',
    on_preview = function(item) M.open_diff(item.absolute) end,
  })
end

function M.summary(path)
  local root = M.root(path); if not root then return '', 0 end
  local branch = run({ 'branch', '--show-current' }, root) or ''
  return vim.trim(branch), #M.status_sync(root)
end

return M
