local M = {}
function M.setup(extra)
  local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(path) then
    if vim.env.COFFE_OFFLINE == "1" then return end
    if vim.fn.executable("git") == 0 then
      vim.notify("Coffe: install Git to enable plugins. Core is available.", vim.log.levels.WARN)
      return
    end
    local output = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
      "https://github.com/folke/lazy.nvim.git", path })
    if vim.v.shell_error ~= 0 then
      vim.notify("Coffe: lazy.nvim download failed. Core is available.\n" .. output, vim.log.levels.WARN)
      return
    end
  end
  vim.opt.rtp:prepend(path)
  local spec = require("coffe.plugins").spec()
  vim.list_extend(spec, extra)
  local lockfile = vim.fn.stdpath("state") .. "/coffe-lazy-lock.json"
  if vim.fn.filereadable(lockfile) == 0 then
    local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
    local bundled = root .. "/lazy-lock.json"
    if vim.fn.filereadable(bundled) == 1 then
      vim.fn.mkdir(vim.fn.stdpath("state"), "p")
      vim.fn.writefile(vim.fn.readfile(bundled), lockfile)
    end
  end
  require("lazy").setup({
    spec = spec, local_spec = false,
    performance = { rtp = { reset = false } },
    lockfile = lockfile,
    checker = { enabled = false }, change_detection = { notify = false },
    install = { colorscheme = { "coffe" } },
  })
end
return M
