local M = {}

-- Cấu hình các biến local trong module
local keyword_file = vim.fn.expand('~/.config/nvim/keywords.txt')
local ns_id = vim.api.nvim_create_namespace('DynamicKeywords')

-- Hàm đọc file keywords
local function load_keywords()
  local keywords = {}
  local f = io.open(keyword_file, "r")
  if not f then return keywords end
  for line in f:lines() do
    local trimmed = line:gsub("%s+", "")
    if trimmed ~= "" then table.insert(keywords, trimmed) end
  end
  f:close()
  return keywords
end

-- Hàm xử lý highlight chính
function M.apply_highlight()
  local keywords = load_keywords()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
      if #keywords == 0 then goto continue end
      
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      
      for l_idx, line in ipairs(lines) do
        local lower_line = string.lower(line)
        
        for _, kw in ipairs(keywords) do
          local lower_kw = string.lower(kw)
          local start_idx = 1
          
          while true do
            local s, e = lower_line:find(lower_kw, start_idx, true)
            if not s then break end
            
            vim.api.nvim_buf_set_extmark(buf, ns_id, l_idx - 1, s - 1, {
              end_col = e,
              hl_group = 'DynamicKeywordMatch',
              priority = 1000,
            })
            start_idx = e + 1
          end
        end
      end
    end
    ::continue::
  end
end

-- [MỚI] Hàm lấy text từ visual mode và ghi vào file
function M.add_visual_keyword()
  -- Thoát visual mode để Neovim cập nhật tọa độ bôi đen ('< và '>)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)

  -- Đợi Neovim xử lý phím Esc xong rồi mới lấy chữ
  vim.schedule(function()
    local _, s_row, s_col, _ = unpack(vim.fn.getpos("'<"))
    local _, e_row, e_col, _ = unpack(vim.fn.getpos("'>"))

    local lines = vim.fn.getline(s_row, e_row)
    if #lines == 0 then return end

    local text = ""
    -- Chỉ hỗ trợ bôi đen trên 1 dòng để tránh lỗi format file
    if #lines == 1 then
      text = string.sub(lines[1], s_col, e_col)
    else
      vim.notify("Vui lòng chỉ bôi đen keyword trên 1 dòng!", vim.log.levels.WARN)
      return
    end

    -- Xóa khoảng trắng thừa ở đầu/cuối
    local keyword = text:gsub("^%s*(.-)%s*$", "%1") 
    if keyword == "" then return end

    -- Mở file ở chế độ "a" (append - ghi nối vào cuối file)
    local f = io.open(keyword_file, "a")
    if f then
      f:write("\n" .. keyword)
      f:close()
      vim.notify("Đã thêm keyword: " .. keyword, vim.log.levels.INFO)
      
      -- Gọi lại hàm để highlight từ khóa mới ngay lập tức
      M.apply_highlight()
    else
      vim.notify("Lỗi: Không thể mở file keywords.txt", vim.log.levels.ERROR)
    end
  end)
end

-- Hàm setup để khởi chạy khi nạp module
function M.setup()
  -- Thiết lập màu sắc
  vim.api.nvim_set_hl(0, 'DynamicKeywordMatch', { fg = '#000000', bg = '#FFB300', bold = true })

  -- Đăng ký sự kiện tự động thay đổi
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufWritePost", "TextChanged", "TextChangedI" }, {
    callback = M.apply_highlight
  })

  -- [MỚI] Map phím <C-x> trong chế độ Visual (v)
  vim.keymap.set('v', '<C-x>', M.add_visual_keyword, { noremap = true, silent = true, desc = "Bắn từ khóa bôi đen vào keywords.txt" })

  -- Kích hoạt ngay lập tức sau 100ms
  vim.defer_fn(M.apply_highlight, 100)
end

return M
