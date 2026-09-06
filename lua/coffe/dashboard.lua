local M={}
local util=require('coffe.util')
function M.open()
  -- Opening a home page never discards unsaved text.
  if vim.bo.modified then vim.cmd('new') end
  local buf=util.scratch('coffe')
  vim.api.nvim_set_current_buf(buf)
  vim.wo.number=false; vim.wo.relativenumber=false; vim.wo.signcolumn='no'
  local lines={
    '', '', '                  ( (', '                   ) )', '                .------.', '                |      |]', '                \\______/',
    '', '                  Coffe', '           A warm place to build.', '',
    '       [n]  Create project', '       [o]  Open project', '       [f]  Find files', '       [g]  Search in files',
    '       [r]  Recent projects', '       [e]  File explorer', '       [s]  Settings', '       [?]  Keyboard guide', '       [q]  Quit', '',
    '       '..vim.fn.fnamemodify(vim.fn.getcwd(),':~'), '', '       Neovim, with a little coffee.',
  }
  util.lines(buf,lines)
  local ns=vim.api.nvim_create_namespace('coffe')
  vim.api.nvim_buf_add_highlight(buf,ns,'Title',8,0,-1)
  for i=11,19 do vim.api.nvim_buf_add_highlight(buf,ns,'Special',i,7,10) end
  local a, p = require('coffe.actions'), require('coffe.projects')
  local actions={n=p.create,o=p.prompt_open,f=a.files,g=a.search,r=p.pick,e=a.explorer,s=a.settings,['?']=function() vim.cmd.CoffeKeys() end,q=function() vim.cmd.quit() end}
  for key,action in pairs(actions) do
    vim.keymap.set('n',key,function() actions[key]() end,{buffer=buf,nowait=true,silent=true})
  end
  vim.keymap.set('n','q','<cmd>quit<CR>',{buffer=buf,silent=true})
  vim.keymap.set('n','<CR>',function()
    local key=lines[vim.api.nvim_win_get_cursor(0)[1]]:match('%[(.)%]')
    if key and actions[key] then actions[key]() end
  end,{buffer=buf,silent=true})
  vim.api.nvim_win_set_cursor(0,{12,0})
end
return M
