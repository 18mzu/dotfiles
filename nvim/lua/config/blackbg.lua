-- Force pure black background everywhere
local black = "#000000"
local groups = {
  "Normal",
  "NormalNC",
  "SignColumn",
  "LineNr",
  "StatusLine",
  "StatusLineNC",
  "EndOfBuffer",
}
for _, g in ipairs(groups) do
  vim.api.nvim_set_hl(0, g, { bg = black })
end
