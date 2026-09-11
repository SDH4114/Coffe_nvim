local M = {}
local util = require('coffe.util')

function M.append(lines, path)
  path = vim.fn.expand(path or require('coffe').config.notes.path)
  local content = {}
  for _, line in ipairs(lines or {}) do if line:match('%S') then content[#content + 1] = line else content[#content + 1] = '' end end
  if vim.trim(table.concat(content, '\n')) == '' then return false end
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local prefix = vim.fn.filereadable(path) == 1 and { '', '' } or {}
  vim.list_extend(prefix, { '## ' .. os.date('%Y-%m-%d %H:%M'), '' })
  vim.list_extend(prefix, content)
  local ok, err = pcall(vim.fn.writefile, prefix, path, 'a')
  if not ok then util.notify('Cannot save note: ' .. tostring(err), vim.log.levels.ERROR) end
  return ok
end

function M.open()
  local buf, win = require('coffe.ui').float({
    filetype = 'markdown', title = 'Coffe · Quick note', footer = 'write to save · q/Esc cancel',
    width = math.floor(vim.o.columns * 0.68), height = math.min(14, vim.o.lines - 6), wrap = true,
  })
  vim.bo[buf].buftype = 'acwrite'; vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '' }); vim.bo[buf].modified = false
  vim.api.nvim_create_autocmd('BufWriteCmd', { buffer = buf, once = false, callback = function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if M.append(lines) then
      vim.bo[buf].modified = false
      util.notify('Note saved: ' .. vim.fn.fnamemodify(vim.fn.expand(require('coffe').config.notes.path), ':~'))
      require('coffe.ui').close(win)
    end
  end })
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, function() vim.bo[buf].modified = false; require('coffe.ui').close(win) end,
      { buffer = buf, silent = true, desc = 'Coffe: Cancel note' })
  end
  vim.cmd.startinsert()
end

return M
