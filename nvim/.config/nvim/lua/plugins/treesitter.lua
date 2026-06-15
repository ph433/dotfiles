return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },

  config = function()
    vim.opt.smartindent = true

    -- 1. Cài đặt các parser ngôn ngữ (thay thế cho ensure_installed)
    require("nvim-treesitter").install({
      "fish", "toml", "lua", "vim", "vimdoc", "markdown", "bash", "commonlisp"
    })

    -- 2. BẬT HIGHLIGHT: Kích hoạt Treesitter bằng API gốc của Neovim (thay thế cho highlight = true)
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
