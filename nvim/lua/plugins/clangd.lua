return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy", -- bật clang-tidy
          "--completion-style=detailed",
          "--header-insertion=never",
          "--fallback-style=llvm", -- style format mặc định
        },
        init_options = {
          clangdFileStatus = true,
        },
        on_attach = function(client, bufnr)
          -- cấu hình diagnostic khi attach
          vim.diagnostic.config({
            virtual_text = { spacing = 2, prefix = "●" }, -- hiện lỗi ngay cạnh dòng
            underline = true,
            signs = true,
            update_in_insert = true, -- báo lỗi cả khi đang Insert
            severity_sort = true,
          })
        end,
      },
    },
  },
}
