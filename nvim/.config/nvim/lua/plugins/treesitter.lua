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
          init_selection = "<CR>",    -- Bấm Enter để bắt đầu
          node_incremental = "v",     -- Spam phím 'v' để bôi đen rộng ra (như cũ!)
          scope_incremental = "grc",
          node_decremental = "grm",   -- Bấm grm để thu hẹp lại
        },
      },
    })
  end,
}
