local M = {}
local function storage() return vim.fn.stdpath('state') .. '/coffe/projects.json' end
function M.recent()
  local ok, lines = pcall(vim.fn.readfile, storage())
  if not ok then return {} end
  local valid, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not valid or type(data) ~= 'table' then return {} end
  return vim.tbl_filter(function(p) return type(p) == 'string' and vim.fn.isdirectory(p) == 1 end, data)
end
function M.remember(path)
  local recent = { path }
  for _, item in ipairs(M.recent()) do
    if item ~= path and #recent < require('coffe').config.projects.recent_limit then recent[#recent + 1] = item end
  end
  vim.fn.mkdir(vim.fn.fnamemodify(storage(), ':h'), 'p')
  local ok, err = pcall(vim.fn.writefile, { vim.json.encode(recent) }, storage())
  if not ok then vim.notify('Coffe: cannot save recent projects: ' .. tostring(err), vim.log.levels.WARN) end
end
function M.open(path)
  path = require('coffe.util').path(path)
  if vim.fn.isdirectory(path) ~= 1 then
    vim.notify('Coffe: folder does not exist: ' .. path, vim.log.levels.WARN)
    return false
  end
  vim.cmd.cd(vim.fn.fnameescape(path))
  M.remember(path)
  if vim.bo.filetype == 'coffe' then vim.cmd.enew() end
  require('coffe.actions').explorer(false)
  return true
end
function M.prompt_open()
  vim.ui.input({ prompt = 'Open project folder: ', default = vim.fn.getcwd() .. '/', completion = 'dir' },
    function(path) if path and path ~= '' then M.open(path) end end)
end
function M.create_at(path)
  path = require('coffe.util').path(path)
  if path == '' or vim.uv.fs_stat(path) then
    vim.notify('Coffe: choose a new folder; this path already exists.', vim.log.levels.WARN)
    return false
  end
  local ok, result = pcall(vim.fn.mkdir, path, 'p')
  if not ok or result == 0 then
    vim.notify('Coffe: could not create folder: ' .. path, vim.log.levels.ERROR)
    return false
  end
  return M.open(path)
end
function M.create()
  local root = vim.fn.expand(require('coffe').config.projects.root)
  vim.ui.input({ prompt = 'Create project folder: ', default = root .. '/', completion = 'dir' },
    function(path) if path and path ~= '' then M.create_at(path) end end)
end
function M.pick()
  local items = M.recent()
  if #items == 0 then return M.prompt_open() end
  vim.ui.select(items, { prompt = 'Recent projects' }, function(path) if path then M.open(path) end end)
end
return M
