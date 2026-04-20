-- ==========================================================================
vim.opt.number = true           -- Hiển thị số dòng
vim.opt.relativenumber = true   -- Số dòng tương đối (cực tốt cho dân Vim)
vim.opt.mouse = 'a'             -- Bật chuột
vim.opt.ignorecase = true       -- Không phân biệt hoa thường khi tìm
vim.opt.smartcase = true        -- Tự nhận diện hoa thường nếu ta gõ chữ Hoa
vim.g.mapleader = ","          -- Phím Leader là Space
vim.opt.clipboard = "unnamedplus" -- Kết nối trực tiếp Clipboard hệ thống
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
vim.keymap.set('n', '<C-c><C-c>', '0"+y$', { desc = 'Copy line content only' })
-- PASTE QUYỀN NĂNG
vim.keymap.set('n', '<C-v>', '"+P', { desc = 'Paste Normal' })
vim.keymap.set('v', '<C-v>', '"_d"+P', { desc = 'Paste Visual (No overwrite clipboard)' })
vim.keymap.set('i', '<C-v>', '<C-r>+', { desc = 'Paste Insert' })

-- VISUAL BLOCK (Chuyển hẳn sang Ctrl+Shift+V)
vim.keymap.set('n', '<C-S-v>', '<C-v>', { desc = 'Visual Block Mode' })

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

-- Trong Visual mode, nhấn Shift + Backspace để xóa toàn bộ các dòng dính líu
vim.keymap.set({'n', 'v'}, '<S-BS>', 'Vd', { desc = "Xóa toàn bộ dòng chứa vùng chọn" })
vim.keymap.set('v', '<Insert>', 'c', { desc = "Xóa vùng chọn và sửa" })

-- ENTER "QUYỀN NĂNG"
vim.keymap.set('n', '<CR>', 'o<ESC>', { desc = 'Enter behaves like o' })

vim.keymap.set('n', '<S-CR>', 'O<ESC>', { desc = 'Shift + Enter behaves like O' })

-- LƯU FILE NHANH (Bonus cho đủ bộ Windows)
vim.keymap.set({'n', 'i', 'v'}, '<C-s>', '<Cmd>w<CR>', { desc = 'Save file' })

-- Mode Normal
vim.keymap.set("n", "<A-Up>", "<cmd>m .-2<cr>==", { desc = "Đẩy dòng lên" })
vim.keymap.set("n", "<A-Down>", "<cmd>m .+1<cr>==", { desc = "Đẩy dòng xuống" })

-- Mode Visual (Bôi đen xong đẩy cả khối)
vim.keymap.set("v", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Đẩy khối lên" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Đẩy khối xuống" })

-- Shift + Backspace để xóa bôi đậm tìm kiếm (Clear Highlight)
vim.keymap.set({'n', 'v'}, '[', '<cmd>w<cr>', { desc = 'Save file' })
-- Shift + [ (tức là phím { ) để đóng file không lưu
vim.keymap.set({'n', 'v'}, '{', '<cmd>q!<cr>', { desc = 'Quit without saving' })
-- Một cách khác nếu không muốn mất phím ]
vim.keymap.set('n', ']', '<cmd>source $MYVIMRC<cr>', { desc = 'Reload config' })

-- Về đầu file: Dòng 1, Cột 1 (Dùng 1| để ép về cột đầu tiên)
vim.keymap.set('n', '<C-Home>', 'gg1|', { desc = 'Start of file' })
vim.keymap.set('i', '<C-Home>', '<C-O>gg<C-O>1|', { desc = 'Start of file' })

-- Về cuối file: Dòng cuối, Cột cuối
vim.keymap.set('n', '<C-End>', 'G$', { desc = 'End of file' })
vim.keymap.set('i', '<C-End>', '<C-O>G<C-O>$', { desc = 'End of file' })

-- vim.keymap.set('n', 'vv', '^vg_', { desc = 'Select line content' })

-- Trong Visual mode: Nhấn '_' để bôi trọn nội dung từ dòng đầu đến dòng cuối
-- (Bỏ qua khoảng trắng ở cả hai đầu của khối dòng đã chọn)
vim.keymap.set('v', 'V', function()
  -- Lấy tọa độ dòng của con trỏ (cursor) và điểm neo (anchor)
  local cursor_line = vim.fn.line('.')
  local anchor_line = vim.fn.line('v')

  if cursor_line > anchor_line then
    -- Đang bôi ĐI XUỐNG: đầu trên (anchor) về 0, đầu dưới (cursor) về $
    return 'o0o$'
  elseif cursor_line < anchor_line then
    -- Đang bôi ĐI LÊN: đầu trên (cursor) về 0, đầu dưới (anchor) về $
    return '0o$o'
  else
    -- Chỉ bôi trên 1 dòng: ép 0 rồi $
    return '0o$'
  end
end, { expr = true, desc = 'Snap to full width (Smart direction)' })
