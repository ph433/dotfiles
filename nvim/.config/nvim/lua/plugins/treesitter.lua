return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    -- Bật tính năng căn lề mặc định của Neovim
    vim.opt.smartindent = true

    -- Gọi trực tiếp hàm setup của nvim-treesitter bản mới
    require("nvim-treesitter").setup({
      ensure_installed = { "fish", "toml", "lua", "vim", "vimdoc", "markdown", "bash" },
      auto_install = true,
    })
  end,
}
