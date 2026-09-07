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
  CoffeDashboardLogo = { fg = "#fabd2f", bold = true },
  CoffeDashboardTagline = { fg = p.muted, italic = true },
  CoffeDashboardButton = { fg = p.fg, bg = "#32302f" },
  CoffeDashboardButtonActive = { fg = "#282828", bg = "#d79921", bold = true },
  CoffeDashboardKey = { fg = "#fe8019", bold = true },
  CoffeDashboardPath = { fg = "#83a598" },
  CoffeSidebarNormal = { fg = p.fg, bg = "#242424" },
  CoffeSidebarTitle = { fg = "#fabd2f", bold = true },
  CoffeSidebarPath = { fg = "#83a598" },
  CoffeSidebarSeparator = { fg = "#504945" },
  CoffeSidebarHint = { fg = p.muted, italic = true },
  CoffeSidebarDirectory = { fg = "#83a598", bold = true },
  CoffeSidebarFile = { fg = p.fg },
  CoffeSidebarSelection = { bg = "#3c3836" },
  CoffePickerNormal = { fg = p.fg, bg = "#32302f" },
  CoffePickerBorder = { fg = "#d79921", bg = "#32302f" },
  CoffePickerTitle = { fg = "#fabd2f", bg = "#32302f", bold = true },
  CoffePickerPrompt = { fg = "#fabd2f", bold = true },
  CoffePickerSelection = { fg = p.fg, bg = "#504945", bold = true },
}
for name, attrs in pairs(groups) do vim.api.nvim_set_hl(0, name, attrs) end
