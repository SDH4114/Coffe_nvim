local M={}
function M.check()
  vim.health.start('Coffe')
  if vim.fn.has('nvim-0.11')==1 then vim.health.ok('Neovim 0.11+') else vim.health.error('Neovim 0.11+ required') end
  if vim.fn.executable('rg')==1 then vim.health.ok('ripgrep available') else vim.health.warn('Install ripgrep for content search and faster file search: brew install ripgrep') end
  if vim.fn.has('clipboard')==1 then vim.health.ok('System clipboard available') else vim.health.warn('No clipboard provider; copy/paste uses Neovim registers') end
  local o=require('coffe.config').options
  if o then vim.health.ok('Coffe configured; settings: '..o.config_file) else vim.health.warn('Call require("coffe").setup()') end
end
return M
