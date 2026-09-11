-- Standalone configuration. For an existing setup, see examples/lazy.lua.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.rtp:prepend(root)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
local config_file = vim.env.COFFE_CONFIG_FILE
if not config_file or config_file == "" then config_file = root .. "/coffe.lua" end
config_file = vim.fn.fnamemodify(vim.fn.expand(config_file), ":p")
local ok, config = pcall(dofile, config_file)
if not ok then
  vim.notify("Coffe configuration error: " .. tostring(config), vim.log.levels.ERROR)
  config = {}
end
config.config_file = config_file
require("coffe").setup(config)
require("coffe.bootstrap").setup(config.plugins or {})
