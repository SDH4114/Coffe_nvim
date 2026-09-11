local M = {}
local util = require('coffe.util')

function M.headings(buf)
  buf = buf or 0
  local items = {}
  local fence
  for index, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local marker = line:match('^%s*(```+)') or line:match('^%s*(~~~+)')
    if marker then
      if not fence then fence = marker:sub(1, 1) elseif marker:sub(1, 1) == fence then fence = nil end
    end
    local hashes, text
    if not fence then hashes, text = line:match('^(#+)%s+(.+)%s*$') end
    if hashes and text and #hashes <= 6 then
      text = text:gsub('%s+#+%s*$', '')
      items[#items + 1] = { level = #hashes, line = index, text = text, label = string.rep('  ', #hashes - 1) .. text }
    end
  end
  return items
end

function M.toggle_checkbox(buf, row)
  buf, row = buf or 0, row or vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
  if not line then return false end
  local changed, count = line:gsub('^(%s*[-*+]%s+)%[([ xX])%]', function(prefix, mark)
    return prefix .. (mark == ' ' and '[x]' or '[ ]')
  end, 1)
  if count == 0 then return false end
  vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { changed })
  return true
end

local function slug(text)
  return text:lower():gsub('[^%w%s%-]', ''):gsub('%s+', '-'):gsub('%-+', '-'):gsub('^%-', ''):gsub('%-$', '')
end

function M.follow_link()
  local line = vim.api.nvim_get_current_line()
  local target = line:match('%b[]%(([^)]+)%)') or line:match('%[%[([^%]]+)%]%]')
  if not target or target:match('^https?://') then return false end
  target = target:gsub('|.*$', '')
  local path, anchor = target:match('^(.-)#(.+)$')
  if not path then path = target end
  if path ~= '' then
    path = vim.fs.normalize(vim.fs.dirname(vim.api.nvim_buf_get_name(0)) .. '/' .. path)
    if vim.fn.filereadable(path) ~= 1 then util.notify('Markdown link not found: ' .. path, vim.log.levels.WARN); return false end
    util.edit(path)
  end
  if anchor then
    for _, item in ipairs(M.headings(0)) do
      if slug(item.text) == slug(anchor) then vim.api.nvim_win_set_cursor(0, { item.line, 0 }); return true end
    end
    util.notify('Markdown heading not found: #' .. anchor, vim.log.levels.WARN)
    return false
  end
  return path ~= ''
end

function M.outline()
  if vim.bo.filetype ~= 'markdown' then return util.notify('CfMarkdown works in a Markdown buffer.', vim.log.levels.WARN) end
  local buf, items = vim.api.nvim_get_current_buf(), M.headings(0)
  if #items == 0 then return util.notify('No Markdown headings found.', vim.log.levels.INFO) end
  require('coffe.picker').open('Markdown outline', items, function(item)
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_set_current_buf(buf); vim.api.nvim_win_set_cursor(0, { item.line, 0 }) end
  end, { footer = 'type filter · Enter jump · Esc close' })
end

function M.setup_buffer(buf)
  local config = require('coffe').config.markdown
  if config.wrap then vim.wo.wrap, vim.wo.linebreak, vim.wo.breakindent = true, true, true end
  local function map(key, fn, desc)
    if key and key ~= '' and vim.fn.maparg(key, 'n', false, true).buffer ~= 1 then
      vim.keymap.set('n', key, fn, { buffer = buf, silent = true, desc = 'Coffe: ' .. desc })
    end
  end
  map(config.outline_key, M.outline, 'Markdown outline')
  map(config.checkbox_key, function() M.toggle_checkbox(buf) end, 'Toggle Markdown checkbox')
  map(config.follow_key, M.follow_link, 'Follow Markdown link')
end

return M
