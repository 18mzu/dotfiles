return {
  {
    -- chạy sớm và mỗi lần đổi colorscheme
    "LazyVim/LazyVim",
    priority = 10000, -- đảm bảo chạy sau khi colorscheme set
    init = function()
      -- bật truecolor (phòng trường hợp bị tắt)
      vim.opt.termguicolors = true

      local function set_black_bg()
        local black = "#000000"
        local groups = {
          "Normal",
          "NormalNC",
          "SignColumn",
          "LineNr",
          "StatusLine",
          "StatusLineNC",
          "EndOfBuffer",
          "NormalFloat",
          "FloatBorder",
          "WinSeparator",
          "Pmenu",
          "PmenuSel",
          "CursorLine",
          "CursorLineNr",
        }
        for _, g in ipairs(groups) do
          -- giữ lại fg hiện tại, chỉ ép bg = #000000
          local cur = vim.api.nvim_get_hl(0, { name = g, link = false }) or {}
          cur.bg = black
          vim.api.nvim_set_hl(0, g, cur)
        end
      end

      -- chạy lúc vào Vim và sau mọi lần đổi theme
      vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
        callback = set_black_bg,
      })
    end,
  },
}
