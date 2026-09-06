-- Isolated demo: nvim -u ./examples/init.lua
local source = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(source, ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.g.mapleader = ' '
local config = root .. '/examples/coffe_config.lua'
local opts = dofile(config)
opts.config_file = config
require('coffe').setup(opts)
