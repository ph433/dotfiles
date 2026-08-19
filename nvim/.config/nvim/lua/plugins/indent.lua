return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  opts = {
    indent = {
      char = "│", -- Ký tự đường kẻ dọc giống VSCode (hoặc "┆", "┊", "▏")
    },
    scope = {
      enabled = true, -- Tự highlight đổi màu đường kẻ cho block code con trỏ đang đứng
      show_start = true,
      show_end = false,
    },
  },
}
