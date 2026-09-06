local M = {}
function M.notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = 'Coffe' })
end
function M.path(path)
  local normalized = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(path), ':p')):gsub('/$', '')
  return normalized == '' and '/' or normalized
end
function M.edit(path)
  -- Leave the sidebar before editing. Keep modified buffers protected by Neovim.
  if vim.bo.filetype == 'coffe_explorer' then
    local target
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      if ft ~= 'coffe_explorer' and vim.api.nvim_win_get_config(win).relative == '' then target = win; break end
    end
    if target then vim.api.nvim_set_current_win(target) else vim.cmd('botright vsplit') end
  end
  local ok, err = pcall(vim.cmd.edit, vim.fn.fnameescape(path))
  if not ok then M.notify(err, vim.log.levels.ERROR) end
end
function M.scratch(ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = ft
  vim.bo[buf].swapfile = false
  return buf
end
function M.lines(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
end
return M
