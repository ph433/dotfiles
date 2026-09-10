vim.opt.number = true           -- Hiển thị số dòng
vim.opt.relativenumber = true   -- Số dòng tương đối
vim.opt.mouse = 'a'             -- Bật chuột
vim.opt.ignorecase = true       -- Không phân biệt hoa thường khi tìm
vim.opt.smartcase = true        -- Tự nhận diện hoa thường nếu ta gõ chữ Hoa
-- vim.g.mapleader = " "
-- vim.g.maplocalleader = " "           -- Phím Leader là dấu phẩy
vim.opt.clipboard = "unnamedplus" -- Clipboard hệ thống
vim.opt.termguicolors = true
-- vim.opt.title = true
-- vim.opt.titlestring = "[NVIM_ACTIVE] %t" -- %t sẽ hiển thị tên file đang mở
vim.opt.title = true
vim.opt.titlelen = 0 -- Không rút ngắn độ dài tiêu đề
vim.opt.titlestring = "%{expand('%:p')}" -- Lấy đầy đủ đường dẫn tuyệt đối
vim.opt.guicursor:append("i:block")
-- 1. Định nghĩa màu cho 2 nhóm con trỏ:
-- bg: màu nền của block con trỏ
-- fg: màu của chữ bên trong khối block đó (khi con trỏ đè lên chữ)
vim.api.nvim_set_hl(0, "NormalCursor", { bg = "#ff0000", fg = "#ffffff" }) -- Đỏ
vim.api.nvim_set_hl(0, "InsertCursor", { bg = "#ffffff", fg = "#000000" }) -- Trắng
-- 2. Gán highlight group tương ứng cho từng mode qua guicursor
vim.opt.guicursor = "n-v-c:block-NormalCursor,i-ci-ve:block-InsertCursor"


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

-- Bật bộ nhớ đệm bytecode để nạp Lua nhanh hơn
if vim.loader then
  vim.loader.enable()
end

-- Đồng bộ phím y/p với clipboard hệ thống X11
vim.opt.clipboard = "unnamedplus"

-- Cố định provider để Neovim không phải quét hệ thống
vim.g.clipboard = {
  name = "xclip",
  copy = {
    ["+"] = "xclip -selection clipboard",
    ["*"] = "xclip -selection primary",
  },
  paste = {
    ["+"] = "xclip -selection clipboard -o",
    ["*"] = "xclip -selection primary -o",
  },
  cache_enabled = 1,
}

local function split_and_indent_normal()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local indent = string.rep(' ', col)

  -- Chèn một dòng mới vào ngay dưới dòng hiện tại
  vim.api.nvim_buf_set_lines(0, row, row, false, { indent })

  -- Đưa con trỏ xuống dòng mới tại đúng vị trí indent
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

vim.keymap.set('n', '<S-CR>', split_and_indent_normal, { 
  desc = 'Tạo dòng mới bên dưới với indent theo vị trí con trỏ' 
})


vim.keymap.set('n', '<C-CR>', function()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  -- Tạo dòng trống cực sạch (indent = 0)
  vim.api.nvim_buf_set_lines(0, row, row, false, { "" })
  -- Nhảy con trỏ xuống dòng đó
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end, { desc = 'Ctrl+Enter xuống dòng indent = 0' })


-- Đây là danh sách các plugin nạp vào Lazy
require("config.autocmds")
require("lazy").setup("plugins")
require("keymaps")
require("keyfunctions")
require("keyfunctions_dir")
require('config.dynamic_keywords').setup()
