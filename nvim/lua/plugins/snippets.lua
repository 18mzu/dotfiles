return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      local luasnip = require("luasnip")

      -- load snippet kiểu VSCode (bao gồm cả friendly-snippets)
      require("luasnip.loaders.from_vscode").lazy_load()

      -- load custom snippet của cậu ở ~/.config/nvim/snippets
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { "~/.config/nvim/snippets" },
      })
    end,
  },
}
