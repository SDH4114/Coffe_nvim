-- Offline fallback; the full standalone setup uses gruvbox.nvim.
vim.cmd.highlight("clear")
vim.g.colors_name = "coffe"
local p = { bg = "#282828", fg = "#ebdbb2", muted = "#928374", accent = "#d79921", green = "#b8bb26" }
local groups = {
  Normal = { fg = p.fg, bg = p.bg }, NormalFloat = { fg = p.fg, bg = "#3c3836" },
  Comment = { fg = p.muted, italic = true }, String = { fg = p.green },
  Function = { fg = "#fabd2f" }, Keyword = { fg = "#fb4934" }, Type = { fg = "#83a598" },
  Number = { fg = "#d3869b" }, Constant = { fg = "#d3869b" }, Statement = { fg = "#fb4934" },
  Identifier = { fg = "#83a598" }, Special = { fg = "#fe8019" }, PreProc = { fg = "#8ec07c" },
  LineNr = { fg = "#665c54" }, CursorLineNr = { fg = p.accent, bold = true },
  Visual = { bg = "#504945" }, Search = { fg = p.bg, bg = p.accent },
  StatusLine = { fg = p.fg, bg = "#504945" }, Pmenu = { fg = p.fg, bg = "#3c3836" },
  PmenuSel = { fg = p.bg, bg = p.accent }, Directory = { fg = "#83a598" },
  CoffeTitle = { fg = "#fabd2f", bold = true }, CoffeMuted = { fg = p.muted },
}
for name, attrs in pairs(groups) do vim.api.nvim_set_hl(0, name, attrs) end
