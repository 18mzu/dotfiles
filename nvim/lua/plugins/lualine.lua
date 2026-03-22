return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      -- theme = "auto", -- ĐỪNG dùng auto (nó sẽ tô màu). Dùng theme trống:
      theme = (function()
        local empty = { bg = "NONE", fg = nil }
        return {
          normal = { a = empty, b = empty, c = empty },
          insert = { a = empty, b = empty, c = empty },
          visual = { a = empty, b = empty, c = empty },
          replace = { a = empty, b = empty, c = empty },
          command = { a = empty, b = empty, c = empty },
          inactive = { a = empty, b = empty, c = empty },
        }
      end)(),
      section_separators = "",
      component_separators = "",
      globalstatus = true,
    },
    sections = {
      lualine_a = {}, -- ẩn mode
      lualine_b = { "branch" }, -- giống fish: chỉ hiện branch
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      -- Thu nhỏ padding để "7:36" ôm mép phải
      lualine_z = { { "location", padding = { left = 0, right = 0 } } },
    },
  },
}
