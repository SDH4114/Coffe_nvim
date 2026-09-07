local M = {}
local util = require('coffe.util')
local function storage() return vim.fn.stdpath('state') .. '/coffe/projects.json' end

local function valid_paths(paths)
  if type(paths) ~= 'table' then return {} end
  return vim.tbl_filter(function(path) return type(path) == 'string' and vim.fn.isdirectory(path) == 1 end, paths)
end

local function load()
  local ok, lines = pcall(vim.fn.readfile, storage())
  if not ok then return { recent = {}, pinned = {} } end
  local valid, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not valid or type(data) ~= 'table' then return { recent = {}, pinned = {} } end
  if vim.islist(data) then return { recent = valid_paths(data), pinned = {} } end
  return { recent = valid_paths(data.recent), pinned = valid_paths(data.pinned) }
end

local function save(data)
  vim.fn.mkdir(vim.fn.fnamemodify(storage(), ':h'), 'p')
  local ok, err = pcall(vim.fn.writefile, { vim.json.encode(data) }, storage())
  if not ok then util.notify('Cannot save recent projects: ' .. tostring(err), vim.log.levels.WARN) end
  return ok
end

function M.recent() return load().recent end
function M.pinned() return load().pinned end

function M.remember(path)
  path = util.path(path)
  local data = load()
  local recent = { path }
  for _, item in ipairs(data.recent) do
    if item ~= path and #recent < require('coffe').config.projects.recent_limit then recent[#recent + 1] = item end
  end
  data.recent = recent
  save(data)
end

function M.forget(path)
  local data = load()
  data.recent = vim.tbl_filter(function(item) return item ~= path end, data.recent)
  data.pinned = vim.tbl_filter(function(item) return item ~= path end, data.pinned)
  return save(data)
end

function M.toggle_pin(path)
  local data, found = load(), false
  for index, item in ipairs(data.pinned) do
    if item == path then table.remove(data.pinned, index); found = true; break end
  end
  if not found then table.insert(data.pinned, 1, path) end
  save(data)
  return not found
end

function M.open(path)
  path = util.path(path)
  if vim.fn.isdirectory(path) ~= 1 then util.notify('Folder does not exist: ' .. path, vim.log.levels.WARN); return false end
  vim.cmd.cd(vim.fn.fnameescape(path))
  M.remember(path)
  local branch_result = vim.fn.executable('git') == 1
    and vim.system({ 'git', '-C', path, 'branch', '--show-current' }, { text = true }):wait() or nil
  local branch = branch_result and branch_result.code == 0 and vim.trim(branch_result.stdout or '') or ''
  util.notify('Project: ' .. vim.fn.fnamemodify(path, ':t') .. (branch ~= '' and (' · git:' .. branch) or ''))
  if vim.bo.filetype == 'coffe' then vim.cmd.enew() end
  require('coffe.actions').explorer(false)
  return true
end

function M.prompt_open()
  vim.ui.input({ prompt = 'Open project folder: ', default = vim.fn.getcwd() .. '/', completion = 'dir' },
    function(path) if path and path ~= '' then M.open(path) end end)
end

function M.create_at(path)
  path = util.path(path)
  if path == '' or vim.uv.fs_stat(path) then
    util.notify('Choose a new folder; this path already exists.', vim.log.levels.WARN); return false
  end
  local ok, result = pcall(vim.fn.mkdir, path, 'p')
  if not ok or result == 0 then util.notify('Could not create folder: ' .. path, vim.log.levels.ERROR); return false end
  return M.open(path)
end

function M.create()
  local root = vim.fn.expand(require('coffe').config.projects.root)
  vim.ui.input({ prompt = 'Create project folder: ', default = root .. '/', completion = 'dir' },
    function(path) if path and path ~= '' then M.create_at(path) end end)
end

function M.pick()
  local data, items, seen = load(), {}, {}
  for _, path in ipairs(data.pinned) do
    items[#items + 1] = { label = '★  ' .. vim.fn.fnamemodify(path, ':~'), path = path, pinned = true }; seen[path] = true
  end
  for _, path in ipairs(data.recent) do
    if not seen[path] then items[#items + 1] = { label = '   ' .. vim.fn.fnamemodify(path, ':~'), path = path } end
  end
  if #items == 0 then return M.prompt_open() end
  require('coffe.picker').open('Projects', items, function(item) M.open(item.path) end, {
    footer = 'type filter · Enter open · Ctrl-T pin · Ctrl-X forget · Esc close',
    on_delete = function(item) M.forget(item.path); return true end,
    actions = { ['<C-t>'] = function(item)
      item.pinned = M.toggle_pin(item.path)
      item.label = (item.pinned and '★  ' or '   ') .. vim.fn.fnamemodify(item.path, ':~')
    end },
  })
end

return M
