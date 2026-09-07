vim.opt.rtp:prepend(vim.fn.getcwd())
local tmp=vim.fn.tempname()
vim.fn.mkdir(tmp,'p'); vim.cmd.cd(vim.fn.fnameescape(tmp))
require('coffe').setup({dashboard=false,undo=false})
local tree=require('coffe.explorer')
tree.open(); vim.api.nvim_set_current_win(tree.win)
local function press(key) vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key,true,false,true),'xt',false) end
local function focus(name)
  tree.refresh(); vim.api.nvim_set_current_win(tree.win)
  for line,entry in pairs(tree.entries) do
    if entry.name==name then vim.api.nvim_win_set_cursor(tree.win,{line,0}); return entry end
  end
  error('Missing tree entry: '..name)
end
vim.ui.input=function(_,cb) cb(tmp..'/folder/') end
press('a'); assert(vim.fn.isdirectory(tmp..'/folder')==1,'create folder')
local folder_path=focus('folder').path
vim.fn.maparg('l','n',false,true).callback(); assert(tree.expanded[folder_path],'l expands folder')
vim.ui.input=function(_,cb) cb(tmp..'/folder/a b.txt') end
press('a'); assert(vim.fn.filereadable(tmp..'/folder/a b.txt')==1,'create file with spaces')
vim.cmd('bdelete')
focus('a b.txt')
vim.fn.maparg('h','n',false,true).callback(); assert(not tree.expanded[folder_path],'h collapses parent from child')
focus('folder'); vim.fn.maparg('l','n',false,true).callback(); focus('a b.txt')
vim.ui.input=function(_,cb) cb(tmp..'/folder/renamed.txt') end
press('r'); assert(vim.fn.filereadable(tmp..'/folder/renamed.txt')==1,'rename file')
focus('renamed.txt')
vim.ui.select=function(_,_,cb) cb('Cancel') end
press('D'); assert(vim.fn.filereadable(tmp..'/folder/renamed.txt')==1,'cancel delete')
vim.ui.select=function(_,_,cb) cb('Delete') end
press('D'); assert(vim.fn.filereadable(tmp..'/folder/renamed.txt')==0,'delete file')
focus('folder'); press('D'); assert(vim.fn.isdirectory(tmp..'/folder')==0,'delete empty directory')
tree.close()
vim.fn.writefile({'needle coffee'},tmp..'/find me.txt')
local picker=require('coffe.picker')
local original=picker.open
local items
picker.open=function(_,results) items=results end
picker.files()
assert(vim.wait(5000,function() return items~=nil end),'async files completes')
assert(#items==1 and items[1].label=='find me.txt','file search finds spaced path')
items=nil
vim.ui.input=function(_,cb) cb('needle') end
picker.grep()
assert(vim.wait(5000,function() return items~=nil end),'async grep completes')
assert(#items==1 and items[1].line==1,'grep finds correct line')
picker.open=original
print('Coffe workflow tests: PASS')
vim.cmd('qa!')
