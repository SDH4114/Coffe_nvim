local M = {}

function M.highlights()
  local groups = {
    CoffeUIBorder = 'FloatBorder', CoffeUITitle = 'Title', CoffeUIFooter = 'Comment',
    CoffeUIKey = 'Special', CoffeUISelection = 'Visual', CoffeUIMuted = 'Comment',
    CoffeUIPath = 'Directory', CoffeUIWarning = 'WarningMsg', CoffeUIError = 'ErrorMsg',
  }
  for name, link in pairs(groups) do vim.api.nvim_set_hl(0, name, { link = link, default = true }) end
end

function M.float(opts)
  opts = opts or {}
  M.highlights()
  local buf = opts.buf or require('coffe.util').scratch(opts.filetype or 'coffe_float')
  local max_width = math.max(1, vim.o.columns - 4)
  local max_height = math.max(1, vim.o.lines - 6)
  local width = math.max(1, math.min(opts.width or 72, max_width))
  local height = math.max(1, math.min(opts.height or 16, max_height))
  local win = vim.api.nvim_open_win(buf, opts.enter ~= false, {
    relative = 'editor', style = 'minimal', border = opts.border or 'rounded',
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    width = width, height = height,
    title = opts.title and (' ' .. opts.title .. ' ') or nil,
    title_pos = opts.title and 'center' or nil,
    footer = opts.footer and (' ' .. opts.footer .. ' ') or nil,
    footer_pos = opts.footer and 'center' or nil,
  })
  vim.wo[win].wrap = opts.wrap == true
  vim.wo[win].cursorline = opts.cursorline == true
  vim.wo[win].cursorlineopt = 'line'
  vim.wo[win].winblend = 0
  vim.wo[win].winhighlight = table.concat({
    'NormalFloat:NormalFloat', 'FloatBorder:CoffeUIBorder', 'FloatTitle:CoffeUITitle',
    'FloatFooter:CoffeUIFooter', 'CursorLine:CoffeUISelection', 'EndOfBuffer:NormalFloat',
  }, ',')
  return buf, win
end

function M.close(win, origin)
  if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  if origin and vim.api.nvim_win_is_valid(origin) then vim.api.nvim_set_current_win(origin) end
end

function M.preview(path, line)
  if vim.fn.filereadable(path) ~= 1 then return end
  local origin = vim.api.nvim_get_current_win()
  local was_insert = vim.api.nvim_get_mode().mode:sub(1, 1) == 'i'
  if was_insert then vim.cmd.stopinsert() end
  local ok, content = pcall(vim.fn.readfile, path, '', 300)
  if not ok then return require('coffe.util').notify(content, vim.log.levels.ERROR) end
  if #content == 0 then content = { '  Empty file' } end
  local buf, win = M.float({
    filetype = vim.filetype.match({ filename = path }) or 'text',
    title = vim.fn.fnamemodify(path, ':~:.'), footer = 'q / Esc close',
    width = math.floor(vim.o.columns * 0.72), height = math.floor(vim.o.lines * 0.7),
  })
  require('coffe.util').lines(buf, content)
  if line and line <= #content then vim.api.nvim_win_set_cursor(win, { line, 0 }) end
  local function close_preview()
    M.close(win, origin)
    if was_insert then vim.schedule(function() if vim.api.nvim_win_is_valid(origin) then vim.cmd.startinsert() end end) end
  end
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, close_preview, { buffer = buf, silent = true })
  end
end

return M
