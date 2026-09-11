local function check()
  assert(require('coffe').config.theme == 'gruvbox')
  assert(vim.g.colors_name == 'gruvbox', 'real Gruvbox not loaded')
  require('lazy').load({ plugins = { 'neo-tree.nvim', 'telescope.nvim', 'nvim-cmp', 'nvim-autopairs', 'gitsigns.nvim', 'lualine.nvim', 'which-key.nvim' } })
  assert(require('cmp').get_config().sources[1].name == 'nvim_lsp')
  vim.cmd.Cf()
  assert(vim.bo.filetype == 'coffe')
  require('coffe.actions').explorer(false)
  assert(vim.wait(3000, function()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == 'neo-tree' then return true end
    end
    return false
  end), 'Neo-tree did not open')
  require('neo-tree.command').execute({ action = 'close' })
  require('coffe.actions').files()
  assert(vim.wait(3000, function() return vim.bo.filetype == 'TelescopePrompt' end), 'Telescope did not open')
  require('telescope.actions').close(vim.api.nvim_get_current_buf())
  assert(vim.v.errmsg == '', vim.v.errmsg)
  print('PASS: real Gruvbox, Neo-tree, Telescope, completion, Git signs, statusline and key hints')
end
vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)
  if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') end
  vim.cmd('qa!')
end, 100)
