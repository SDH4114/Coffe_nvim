-- Standalone configuration. For an existing setup, see examples/lazy.lua.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.rtp:prepend(root)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
local ok, config = pcall(dofile, root .. "/coffe.lua")
if not ok then
  vim.notify("Coffe configuration error: " .. tostring(config), vim.log.levels.ERROR)
  config = {}
end
config.config_file = root .. "/coffe.lua"
require("coffe").setup(config)
require("coffe.bootstrap").setup(config.plugins or {})
