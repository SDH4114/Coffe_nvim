local M = {}

local function git_branch()
  return vim.b.coffe_git_head or ''
end

local function git_changes()
  return vim.b.coffe_git_changes or 0
end

function M.update_branch()
  if vim.fn.executable('git') ~= 1 then return end
  local buffer = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buffer)
  local cwd = path ~= '' and vim.fs.dirname(path) or vim.fn.getcwd()
  vim.system({ 'git', '-C', cwd, 'branch', '--show-current' }, { text = true }, function(result)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buffer) then
        vim.b[buffer].coffe_git_head = result.code == 0 and vim.trim(result.stdout or '') or ''
        vim.cmd.redrawstatus()
      end
    end)
  end)
  vim.system({ 'git', '-C', cwd, 'status', '--porcelain=v1', '-z' }, { text = false }, function(result)
    local count = 0
    if result.code == 0 then for _ in (result.stdout or ''):gmatch('[^%z]+') do count = count + 1 end end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buffer) then vim.b[buffer].coffe_git_changes = count; vim.cmd.redrawstatus() end
    end)
  end)
end

function M.render()
  if vim.bo.buftype ~= '' then return ' %f %=%l:%c ' end
  local name = vim.fn.expand('%:t')
  if name == '' then name = '[No name]' end
  local modified = vim.bo.modified and ' [+]' or ''
  local readonly = vim.bo.readonly and ' [RO]' or ''
  local branch = git_branch()
  local changes = git_changes()
  local diagnostics = vim.diagnostic.count(0)
  local errors = diagnostics[vim.diagnostic.severity.ERROR] or 0
  local warnings = diagnostics[vim.diagnostic.severity.WARN] or 0
  local diag = (errors + warnings) > 0 and string.format(' E:%d W:%d', errors, warnings) or ''
  local git = branch ~= '' and ('  git:' .. branch .. (changes > 0 and (' ±' .. changes) or '')) or ''
  local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'text'
  local project = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  return string.format(' %s%s%s%s%%=%s  %s  %s  %%l:%%c ', name, modified, readonly, git, diag, project, ft)
end

function M.setup()
  _G.CoffeStatusline = M
  if vim.o.statusline == '' then vim.o.statusline = '%!v:lua.CoffeStatusline.render()' end
  local group = vim.api.nvim_create_augroup('CoffeStatusline', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'DirChanged' }, { group = group, callback = M.update_branch })
  M.update_branch()
end

return M
