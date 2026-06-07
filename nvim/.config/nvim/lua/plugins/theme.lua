return {
  "maxmx03/dracula.nvim", -- 🎯 CHUẨN PHOM Ở ĐÂY (Thêm số 3 vào đuôi)
  lazy = false,
  priority = 1000,
  config = function()
    require("dracula").setup({
      colors = {
        bg = "#000000",          -- Ép nền đen xì nguyên khối đúng gu ông
        bg_dark = "#000000",     
        bg_float = "#000000",    
        bg_sidebar = "#000000",  
        statusline_bg = "#000000",
      },
      show_end_of_buffer = false, 
      transparent_bg = false,
      lualine_bg_color = "#000000",
    })
    
    vim.cmd[[colorscheme dracula]]
  end,
}
