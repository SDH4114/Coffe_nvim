local function main()
vim.opt.rtp:prepend(vim.env.COFFE_TEST_ROOT)
local tmp = vim.env.COFFE_TEST_TMP .. '/features'
vim.fn.mkdir(tmp, 'p')
local inbox = tmp .. '/notes/inbox.md'
require('coffe').setup({
  dashboard = false, undo = false,
  notes = { path = inbox }, sessions = { enabled = true, auto_restore = true },
})

local function check(value, message) assert(value, message) end
for _, name in ipairs({ 'Cf', 'CfNote', 'CfMarkdown', 'CfGit', 'CfDiff', 'CfDiffAll', 'CfFiles', 'CfKeys' }) do
  check(vim.fn.exists(':' .. name) == 2, 'missing command :' .. name)
end
local user_commands = vim.api.nvim_get_commands({ builtin = false })
for _, name in ipairs({ 'Coffe', 'CoffeNote', 'CoffeProblems', 'CoffeSymbols', 'CoffeTasks',
  'CoffeSessionSave', 'CoffeSessionRestore', 'cm' }) do
  check(user_commands[name] == nil, 'removed command still exists :' .. name)
end

local markdown = require('coffe.markdown')
local md = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(md, 0, -1, false, { '# Title', 'text', '## Child', '- [ ] task', '```lua', '# Not a heading', '```' })
local headings = markdown.headings(md)
check(#headings == 2 and headings[2].level == 2 and headings[2].line == 3 and headings[2].text == 'Child', 'markdown headings')
markdown.toggle_checkbox(md, 4)
check(vim.api.nvim_buf_get_lines(md, 3, 4, false)[1] == '- [x] task', 'checkbox checks')
markdown.toggle_checkbox(md, 4)
check(vim.api.nvim_buf_get_lines(md, 3, 4, false)[1] == '- [ ] task', 'checkbox unchecks')
vim.api.nvim_buf_delete(md, { force = true })

local notes = require('coffe.notes')
check(notes.append({ 'first line', 'second line' }, inbox), 'note append failed')
local note_text = table.concat(vim.fn.readfile(inbox), '\n')
check(note_text:find('first line', 1, true) and note_text:find('second line', 1, true), 'note content missing')

local sessions = require('coffe.sessions')
local project = tmp .. '/session project'
vim.fn.mkdir(project, 'p')
local saved = project .. '/saved file.txt'
local split_file = project .. '/split file.txt'
local tab_file = project .. '/tab file.txt'
vim.fn.writefile({ 'one', 'two', 'three' }, saved)
vim.fn.writefile({ 'split' }, split_file); vim.fn.writefile({ 'tab' }, tab_file)
vim.cmd.cd(vim.fn.fnameescape(project)); vim.cmd.edit(vim.fn.fnameescape(saved))
vim.api.nvim_win_set_cursor(0, { 2, 1 })
vim.cmd.vsplit(vim.fn.fnameescape(split_file))
vim.cmd.tabnew(vim.fn.fnameescape(tab_file))
check(sessions.save(project), 'session save failed')
vim.cmd('tabonly!'); vim.cmd('%bwipeout!'); vim.cmd.enew()
check(sessions.restore(project), 'session restore failed')
check(#vim.api.nvim_list_tabpages() == 2, 'session tabs not restored')
check(#vim.api.nvim_tabpage_list_wins(vim.api.nvim_list_tabpages()[1]) == 2, 'session splits not restored')
vim.cmd.tabfirst(); vim.cmd.wincmd('h')
check(vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)) == vim.uv.fs_realpath(saved), 'session file not restored')
check(vim.api.nvim_win_get_cursor(0)[1] == 2, 'session cursor not restored')
vim.api.nvim_set_current_line('changed')
check(not sessions.restore(project), 'session restore replaced modified buffer')
vim.cmd('bwipeout!'); vim.cmd.enew()
local corrupt_project = tmp .. '/corrupt session'; vim.fn.mkdir(corrupt_project, 'p')
vim.fn.mkdir(vim.fn.fnamemodify(sessions.path(corrupt_project), ':h'), 'p')
vim.fn.writefile({ 'not json' }, sessions.path(corrupt_project))
check(not sessions.restore(corrupt_project), 'corrupt session was accepted')

local repo = tmp .. '/git repo'
vim.fn.mkdir(repo, 'p')
vim.system({ 'git', '-C', repo, 'init', '-q' }):wait()
vim.system({ 'git', '-C', repo, 'config', 'user.email', 'coffe@example.test' }):wait()
vim.system({ 'git', '-C', repo, 'config', 'user.name', 'Coffe Test' }):wait()
vim.fn.writefile({ 'before' }, repo .. '/tracked file.txt')
vim.system({ 'git', '-C', repo, 'add', '--', 'tracked file.txt' }):wait()
vim.system({ 'git', '-C', repo, 'commit', '-qm', 'initial' }):wait()
vim.fn.writefile({ 'after' }, repo .. '/tracked file.txt')
vim.fn.writefile({ 'new' }, repo .. '/new file.md')
local git = require('coffe.git')
local status = git.status_sync(repo)
check(#status == 2, 'git status count')
local by_path = {}; for _, item in ipairs(status) do by_path[item.path] = item end
check(by_path['tracked file.txt'].unstaged, 'unstaged file missing')
check(by_path['new file.md'].untracked, 'untracked file missing')
check(git.diff_sync(repo, 'tracked file.txt'):find('%+after'), 'file diff missing')
vim.system({ 'git', '-C', repo, 'add', '--', 'tracked file.txt' }):wait()
local staged = git.status_sync(repo); local staged_by_path = {}
for _, item in ipairs(staged) do staged_by_path[item.path] = item end
check(staged_by_path['tracked file.txt'].staged, 'staged file missing')
check(git.diff_sync(repo, 'tracked file.txt', true):find('%+after'), 'staged diff missing')

print('Coffe feature tests: PASS')
vim.cmd('qa!')
end

local ok, err = xpcall(main, debug.traceback)
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') end
