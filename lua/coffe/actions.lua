local M = {}
function M.settings()
  vim.cmd.edit(vim.fn.fnameescape(require("coffe").config.config_file))
end
function M.explorer(toggle)
  local c = require("coffe").config.explorer
  local ok, tree = pcall(require, "neo-tree.command")
  if ok then
    tree.execute({ toggle = toggle ~= false, position = c.side, dir = vim.fn.getcwd() })
    return
  end
  local fallback = require("coffe.explorer")
  if toggle == false then fallback.open() else fallback.toggle() end
end
function M.files()
  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then return telescope.find_files({ hidden = true }) end
  return require("coffe.picker").files()
end
function M.search()
  if vim.fn.executable("rg") == 0 then
    return vim.notify("Coffe: install ripgrep for project text search.", vim.log.levels.WARN)
  end
  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then return telescope.live_grep() end
  return require("coffe.picker").grep()
end
function M.recent()
  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then return telescope.oldfiles() end
  return require("coffe.picker").recent()
end
function M.buffers()
  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then return telescope.buffers({ sort_mru = true, ignore_current_buffer = false }) end
  return require("coffe.picker").buffers()
end
function M.palette()
  local projects = require("coffe.projects")
  local items = {
    { label = "Files · Find files", run = M.files },
    { label = "Files · Search project text", run = M.search },
    { label = "Files · Recent files", run = M.recent },
    { label = "Workspace · Switch buffer", run = M.buffers },
    { label = "Workspace · Toggle explorer", run = M.explorer },
    { label = "Workspace · Dashboard", run = function() require("coffe.dashboard").open() end },
    { label = "Projects · Create project", run = projects.create },
    { label = "Projects · Open folder", run = projects.prompt_open },
    { label = "Projects · Recent and pinned", run = projects.pick },
    { label = "Coffe · Open settings", run = M.settings },
    { label = "Coffe · Keyboard guide", run = function() vim.cmd.CoffeKeys() end },
    { label = "Editor · Save file", run = function() vim.cmd.write() end },
  }
  require("coffe.picker").open("Commands", items, function(item) item.run() end, {
    empty = "  No commands found",
    footer = "type command · Enter run · Esc close",
  })
end
function M.delete_line()
  if not vim.bo.modifiable or vim.bo.readonly then return end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  -- Keep deletion in the unnamed register so p can recover it.
  local line = vim.api.nvim_get_current_line()
  vim.fn.setreg('"', line .. "\n", "V")
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, {})
end
function M.paste()
  local register = vim.fn.has("clipboard") == 1 and "+" or '"'
  local lines = vim.fn.getreg(register, 1, true)
  if #lines == 0 then return end
  vim.api.nvim_paste(table.concat(lines, "\n"), false, -1)
end
return M
