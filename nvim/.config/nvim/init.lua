-- ==========================================================================
-- 1. CẤU HÌNH HỆ THỐ N   G
--  = = = = = = = = =  =   = ===============================================================
vim.opt.number = true           -- Hiển thị số dòng
vim.opt.relativenumber = true   -- Số dòng tương đối (cực tốt cho dân Vim)
vim.opt.mouse = 'a'             -- Bật chuột
vim.opt.ignorecase = true       -- Không phân biệt hoa thường khi tìm
vim.opt.smartcase = true        -- Tự nhận diện hoa thường nếu ta gõ chữ Hoa
vim.g.mapleader = ","          -- Phím Leader là Space
vim.opt.clipboard = "unnamedplus" -- Kết nối trực tiếp Clipboard hệ thống
vim.opt.keymodel = 'startsel,stopsel'
-- ==========================================================================
-- 2. ĐỊNH DẠNG FILE & TỰ ĐỘNG HÓA (AUTOCMDS)
-- ==========================================================================
-- Nhận diện file Kanata (.kbd) là lisp để có màu và comment đúng
vim.filetype.add({
  extension = { kbd = "lisp" },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lisp",
  callback = function()
    vim.bo.commentstring = ";; %s"
  end,
})

local function shift_move(key)
    local mode = vim.api.nvim_get_mode().mode
    if mode == 'n' or mode == 'i' then
        return '<Esc>v' .. key
    end
    return key
end

local opts_expr = { expr = true, noremap = true, silent = true }

vim.keymap.set({'n', 'i', 'v'}, '<S-Right>', function() return shift_move('<Right>') end, opts_expr)
vim.keymap.set({'n', 'i', 'v'}, '<S-Left>',  function() return shift_move('<Left>')  end, opts_expr)
vim.keymap.set({'n', 'i', 'v'}, '<S-Up>',    function() return shift_move('<Up>')    end, opts_expr)
vim.keymap.set({'n', 'i', 'v'}, '<S-Down>',  function() return shift_move('<Down>')  end, opts_expr)

-- ==========================================================================
-- 3. PHÍM TẮT HỆ THỐNG (WINDOWS-STYLE)
-- ==========================================================================

-- CHỌN TẤT CẢ (Select All)
-- Dùng <Cmd> thay cho gõ lệnh trực tiếp để mượt hơn
vim.keymap.set({'n', 'i', 'v'}, '<C-a>', '<Esc>ggVG', { desc = 'Select All' })

-- COPY & PASTE (Sửa lỗi dùng register "+")
-- Copy trong Visual mode
vim.keymap.set('v', '<C-c>', '"+y', { desc = 'Copy to clipboard' })

-- ==========================================================================
-- COPY QUYỀN NĂNG (Ctrl + C y hệt phím y)
-- ==========================================================================

-- Trong Visual mode: Copy vùng đang bôi đen
vim.keymap.set('v', '<C-c>', '"+y', { desc = 'Copy selection' })

-- Trong Normal mode: Biến Ctrl-C thành phím chức năng Copy (Operator)
-- Giờ bạn có thể bấm Ctrl-C Ctrl-C để copy dòng, hoặc Ctrl-C + w để copy từ.
vim.keymap.set('n', '<C-c>', '"+y', { desc = 'Copy operator' })

-- Đặc cách: Nhấn Ctrl-C 2 lần để copy cả dòng (giống yy)
vim.keymap.set('n', '<C-c><C-c>', '"+yy', { desc = 'Copy line' })

-- Dán phía sau con trỏ (giống p)
vim.keymap.set('n', '<C-v>', '"+p', { desc = 'Paste after' })

-- Dán phía trước con trỏ (giống P)
vim.keymap.set('n', '<C-S-v>', '"+P', { desc = 'Paste before' })

-- Thay cả dòng nhưng không làm mất nội dung đã copy
vim.keymap.set('n', '<C-A-v>', 'V"_d"+P', { noremap = true, desc = 'Thay cả dòng bằng clipboard' })

-- UNDO & REDO
vim.keymap.set({'n', 'i', 'v'}, '<C-z>', '<Cmd>undo<CR>', { desc = 'Undo' })
vim.keymap.set({'n', 'i', 'v'}, '<C-y>', '<Cmd>redo<CR>', { desc = 'Redo' })

-- TÌM KIẾM (Search)
vim.keymap.set({'n', 'i', 'v'}, '<C-f>', '<Esc>/', { desc = 'Search' })

-- ==========================================================================
-- 4. PHÍM TẮT DI CHUYỂN & CHỈNH SỬA (CUSTOM)
-- ==========================================================================

-- BACKSPACE (Xóa ký tự ở Normal mode giống X)
-- Normal mode: Xóa lùi 1 ký tự (X)
vim.keymap.set('n', '<BS>', 'X', { desc = 'Backspace xóa lùi 1 ký tự' })

-- Visual mode: Xóa CHÍNH XÁC vùng chọn (x), không xóa cả dòng
vim.keymap.set('v', '<BS>', 'x', { desc = 'Backspace xóa chính xác vùng chọn' })
-- ENTER "QUYỀN NĂNG"
-- Enter = o (Xuống dòng dưới + Insert)
vim.keymap.set('n', '<CR>', 'o', { desc = 'Enter behaves like o' })

-- Shift + Enter = O (Xuống dòng trên + Insert)
-- Lưu ý: Nếu Terminal không nhận, hãy kiểm tra cài đặt Terminal của bạn
vim.keymap.set('n', '<S-CR>', 'O', { desc = 'Shift + Enter behaves like O' })

-- VISUAL BLOCK (Chuyển sang Ctrl+Shift+V vì Ctrl+V đã làm phím Paste)
vim.keymap.set({'n', 'v'}, '<C-S-v>', '<C-v>', { desc = 'Visual Block Mode' })

-- LƯU FILE NHANH (Bonus cho đủ bộ Windows)
vim.keymap.set({'n', 'i', 'v'}, '<C-s>', '<Cmd>w<CR>', { desc = 'Save file' })

-- Mode Normal
vim.keymap.set("n", "<A-Up>", "<cmd>m .-2<cr>==", { desc = "Đẩy dòng lên" })
vim.keymap.set("n", "<A-Down>", "<cmd>m .+1<cr>==", { desc = "Đẩy dòng xuống" })

-- Mode Visual (Bôi đen xong đẩy cả khối)
vim.keymap.set("v", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Đẩy khối lên" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Đẩy khối xuống" })

-- Shift + Backspace để xóa bôi đậm tìm kiếm (Clear Highlight)
vim.keymap.set("n", "<S-BS>", "<cmd>noh<cr>", { silent = true, desc = "Clear search highlight" })
vim.keymap.set('n', '<Space>', 'i <Esc> <Rivght>', { noremap = true, desc = 'Chèn dấu cách tại chỗ' })
vim.keymap.set({'n', 'v'}, '[', '<cmd>w<cr>', { desc = 'Save file' })
-- Shift + [ (tức là phím { ) để đóng file không lưu
vim.keymap.set({'n', 'v'}, '{', '<cmd>q!<cr>', { desc = 'Quit without saving' })
-- Một cách khác nếu không muốn mất phím ]
vim.keymap.set('n', ']', '<cmd>source $MYVIMRC<cr>', { desc = 'Reload config' })
