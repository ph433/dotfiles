return {
  "maxmx03/dracula.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("dracula").setup({
      colors = {
        bg = "#000000",
        bg_dark = "#000000",
        bg_float = "#000000",
        bg_sidebar = "#000000",
        statusline_bg = "#000000",
      },
      show_end_of_buffer = false,
      transparent_bg = false,
      lualine_bg_color = "#000000",
    })
    
    -- Kích hoạt theme gốc trước
    vim.cmd([[colorscheme dracula]])

    -- 🚀 ĐƯỜNG QUYỀN ĐÈ BẸP TRONG SUỐT: Chạy sau một nhịp để ép màu đen xì bằng lệnh lõi
    vim.schedule(function()
      local bg_den_tuyet_doi = { bg = "#000000", ctermbg = "black" }
      local groups = { 
        "Normal", "NormalNC", "SignColumn", "FoldColumn", 
        "LineNr", "CursorLineNr", "StatusLine", "StatusLineNC",
        "NeoTreeNormal", "NvimTreeNormal", "EndOfBuffer"
      }
      for _, group in ipairs(groups) do
        vim.api.nvim_set_hl(0, group, bg_den_tuyet_doi)
      end
    end)
  end,
}
