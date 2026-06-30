return {
  "lfv89/vim-interestingwords",
  config = function()
    -- 1. Tắt map phím mặc định của plugin
    vim.g.interestingWordsDefaultMappings = 0
    
    -- 2. TÙY CHỈNH MÀU SẮC ĐỂ ĐỠ CHÓI (Màu Pastel / Soft Colors)
    -- Danh sách mã màu Hex dành cho Neovim có `termguicolors`
    vim.g.interestingWordsGUIColors = {
      '#8CC4FF', -- Xanh dương nhạt
      '#A4E57E', -- Xanh lá nhạt
      '#FFDB72', -- Vàng nhạt
      '#FF8A8A', -- Đỏ hồng nhạt
      '#FFB3FF', -- Tím nhạt
      '#99E6E6', -- Xanh lơ nhạt
    }
    
    -- Danh sách mã màu dành cho Terminal (nếu không dùng True Color)
    vim.g.interestingWordsTermColors = {
      '117', -- Xanh dương nhạt
      '120', -- Xanh lá nhạt
      '222', -- Vàng nhạt
      '210', -- Đỏ nhạt
      '225', -- Tím nhạt
      '122', -- Xanh lơ nhạt
    }
    
    -- 3. Map phím h và H để tô màu theo ý bạn
    vim.keymap.set('n', 'h', ":call InterestingWords('n')<CR>", { silent = true })
    vim.keymap.set('v', 'h', ":call InterestingWords('v')<CR>", { silent = true })
    vim.keymap.set('n', 'H', ":call UncolorAllWords()<CR>", { silent = true })
    
    -- 4. ĐOẠN ĐIỀU HƯỚNG CHUẨN: Bọc số 1 và 0 trong dấu nháy đơn
    vim.keymap.set('n', 'n', ":call WordNavigation('1')<CR>", { silent = true })
    vim.keymap.set('n', 'N', ":call WordNavigation('0')<CR>", { silent = true })
  end
}
