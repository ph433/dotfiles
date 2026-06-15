return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    -- Plugin này sẽ mang 100% tính năng spam 'v' và highlight cũ quay trở lại
    "MeanderingProgrammer/treesitter-modules.nvim",
  },
  
  config = function()
    vim.opt.smartindent = true

    -- 1. Cài đặt các parser
    require("nvim-treesitter").install({
      "fish", "toml", "lua", "vim", "vimdoc", "markdown", "bash", "commonlisp"
    })

    -- 2. Khôi phục thói quen cấu hình cũ bằng plugin vệ tinh
    require('treesitter-modules').setup({
      highlight = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<F2>",       -- Bấm phím F2 để bắt đầu chọn vùng code
          node_incremental = "<F3>",     -- Bấm phím F3 để bôi đen rộng ra từ từ (theo node)
          scope_incremental = "S-v",     -- Bấm Shift + v để bôi đen nhanh toàn bộ hàm/khối code
          node_decremental = "<F1>",     -- Bấm phím F1 để thu hẹp vùng chọn lại
        },
      },
    })
  end,
}
