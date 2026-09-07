vim.opt.rtp:prepend(vim.env.COFFE_TEST_ROOT)
local function check()
  require("coffe").setup({ clipboard = false, dashboard = false, theme = "coffe", keys = { delete_line = "<D-BS>" } })
  local a, p = require("coffe.actions"), require("coffe.projects")
  assert(vim.g.colors_name == "coffe")
  assert(vim.fn.maparg("<C-r>", "n") == "", "native redo changed")
  assert(vim.fn.maparg("<C-v>", "n") == "", "native visual block changed")
  assert(vim.fn.maparg("u", "n") == "", "native undo changed")
  assert(vim.fn.maparg("<leader><space>", "n", false, true).callback ~= nil, "missing command palette mapping")
  assert(vim.fn.maparg("<leader>bb", "n", false, true).callback ~= nil, "missing buffer picker mapping")
  assert(vim.fn.maparg("<D-BS>", "i", false, true).callback ~= nil, "missing Cmd-Backspace")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three" })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  -- Break the API undo block before testing a user action.
  vim.cmd('let &ul = &ul')
  a.delete_line()
  assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ",") == "one,three")
  vim.cmd.undo()
  assert(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == "two", "line deletion cannot be undone")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "last" })
  a.delete_line()
  assert(vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_get_current_line() == "")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved text" })
  local original = vim.api.nvim_get_current_buf()
  require("coffe.dashboard").open()
  assert(vim.bo.filetype == "coffe")
  assert(vim.api.nvim_buf_get_lines(original, 0, 1, false)[1] == "unsaved text")
  assert(vim.bo[original].modified, "dashboard discarded changes")
  local dashboard = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(dashboard:find("██████", 1, true) or dashboard:find("C  O  F  F  E", 1, true), "large COFFE logo missing")
  assert(not dashboard:find("Neovim, with a little coffee", 1, true), "old tagline is still visible")
  -- Stub explorer only to isolate project IO from interactive window management.
  local explorer = a.explorer
  a.explorer = function() end
  local path = vim.env.COFFE_TEST_TMP .. "/project with spaces | literal"
  assert(p.create_at(path), "project creation failed")
  assert(vim.uv.fs_realpath(vim.fn.getcwd()) == vim.uv.fs_realpath(path))
  assert(not p.create_at(path), "existing project should not be replaced")
  assert(not p.open(path .. "/missing"))
  p.remember(path)
  assert(#p.recent() == 1 and p.recent()[1] == path)
  assert(p.toggle_pin(path) and p.pinned()[1] == path, "project was not pinned")
  assert(not p.toggle_pin(path) and #p.pinned() == 0, "project was not unpinned")
  assert(require('coffe.statusline').render():find('project with spaces | literal', 1, true), "statusline misses project")
  vim.fn.writefile({ "invalid json" }, vim.fn.stdpath("state") .. "/coffe/projects.json")
  assert(#p.recent() == 0, "corrupt history must not crash")
  a.explorer = explorer
  vim.cmd.enew()
  vim.cmd.CoffeKeys()
  assert(vim.bo.filetype == "coffe_help")
  vim.cmd.close()
  vim.cmd.CoffeCommands()
  local palette = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(palette:find("Find files", 1, true), "command palette misses file action")
  local palette_escape = vim.fn.maparg('<Esc>', 'i', false, true).callback
  if palette_escape then palette_escape() else vim.cmd.close() end
  assert(vim.api.nvim_get_mode().mode:sub(1, 1) ~= 'i', "picker returns to dashboard in insert mode")
  -- All source files parse, including optional plugin specs.
  for _, file in ipairs(vim.fn.glob(vim.env.COFFE_TEST_ROOT .. "/**/*.lua", false, true)) do
    assert(loadfile(file), "invalid Lua: " .. file)
  end
  print("PASS: core editing, native keys, dashboard, project safety, persistence, commands, Lua syntax")
end
local ok, err = xpcall(check, debug.traceback)
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
vim.cmd("qa!")
