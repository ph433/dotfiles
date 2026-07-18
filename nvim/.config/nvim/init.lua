vim.opt.number = true           -- Hiển thị số dòng
vim.opt.relativenumber = true   -- Số dòng tương đối
vim.opt.mouse = 'a'             -- Bật chuột
vim.opt.ignorecase = true       -- Không phân biệt hoa thường khi tìm
vim.opt.smartcase = true        -- Tự nhận diện hoa thường nếu ta gõ chữ Hoa
vim.g.mapleader = ","           -- Phím Leader là dấu phẩy
vim.opt.clipboard = "unnamedplus" -- Clipboard hệ thống
vim.opt.termguicolors = true
vim.opt.title = true
vim.opt.titlestring = "[NVIM_ACTIVE] %t" -- %t sẽ hiển thị tên file đang mở

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.g.lazy_did_setup or vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
     Pia }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)


-- Đây là danh sách các plugin nạp vào Lazy
require("config.autocmds")
require("lazy").setup("plugins")
require("keymaps")
require("keyfunctions")

-- Định nghĩa đường dẫn file keyword
_G.keyword_file = vim.fn.expand('~/.config/nvim/keywords.txt')
local ns_id = vim.api.nvim_create_namespace('DynamicKeywords')

-- Tạo nhóm màu (Nền vàng, chữ đen, in đậm)
vim.api.nvim_set_hl(0, 'DynamicKeywordMatch', { fg = '#000000', bg = '#FFB300', bold = true })

-- Đổi thành hàm Toàn cục (_G.) để debug được từ dòng lệnh
_G.load_keywords = function()
  local keywords = {}
  local f = io.open(_G.keyword_file, "r")
  if not f then return keywords end
  for line in f:lines() do
    local trimmed = line:gsub("%s+", "")
    if trimmed ~= "" then table.insert(keywords, trimmed) end
  end
  f:close()
  return keywords
end

_G.apply_highlight = function()
  local keywords = _G.load_keywords()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
      if #keywords == 0 then goto continue end
      
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      
      -- ĐÃ SỬA LỖI Ở ĐÂY: Thêm 'in ipairs(lines)'
      for l_idx, line in ipairs(lines) do
        -- Chuyển toàn bộ dòng về chữ thường để so sánh không phân biệt hoa thường
        local lower_line = string.lower(line)
        
        for _, kw in ipairs(keywords) do
          -- Chuyển keyword về chữ thường
          local lower_kw = string.lower(kw)
          local start_idx = 1
          
          while true do
            -- Tìm kiếm dựa trên chuỗi đã chuyển về chữ thường
            local s, e = lower_line:find(lower_kw, start_idx, true)
            if not s then break end
            
            -- extmark vẫn được đặt vào dòng gốc (`line`) dựa trên tọa độ tìm thấy
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

-- Kích hoạt sự kiện liên tục: Khi đổi buffer, khi lưu file, HOẶC khi thay đổi văn bản (TextChanged)
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufWritePost", "TextChanged", "TextChangedI" }, {
  callback = _G.apply_highlight
})

-- Chạy ngay lập tức khi khởi động
vim.defer_fn(_G.apply_highlight, 100)
