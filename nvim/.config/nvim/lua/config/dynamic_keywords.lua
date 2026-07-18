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

-- Hàm setup để khởi chạy khi nạp module
function M.setup()
  -- Thiết lập màu sắc (Nền vàng, chữ đen, in đậm)
  vim.api.nvim_set_hl(0, 'DynamicKeywordMatch', { fg = '#000000', bg = '#FFB300', bold = true })

  -- Đăng ký sự kiện tự động thay đổi
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufWritePost", "TextChanged", "TextChangedI" }, {
    callback = M.apply_highlight
  })

  -- Kích hoạt ngay lập tức sau 100ms
  vim.defer_fn(M.apply_highlight, 100)
end

return M
