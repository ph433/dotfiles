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

-- COPY
vim.keymap.set('v', '<C-c>', '"+y', { desc = 'Copy selection' })
vim.keymap.set('n', '<C-c>', '"+yy', { desc = 'Copy current line' }) -- Copy dòng nhanh
vim.keymap.set('n', '<C-c><C-c>', 'gg"+yG', { desc = 'Copy toàn bộ file' }) -- Bonus: Nhấn 2 lần copy cả file

-- PASTE QUYỀN NĂNG
vim.keymap.set('n', '<C-v>', '"+P', { desc = 'Paste Normal' })
vim.keymap.set('v', '<C-v>', '"_c<C-r>+<Esc>', { desc = 'Change and Paste from clipboard' })
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

vim.keymap.set({'n', 'x'}, 'V', function()
  local mode = vim.fn.mode()
  
  -- \22 là mã của Visual Block (<C-v>)
  if mode == '\22' then 
    -- LẦN 2: Ép về Normal rồi mới chọn toàn bộ để tránh bị dính mode cũ
    -- Hoặc dùng lệnh feedkeys để thực thi chuỗi sạch hơn
    return '<Esc>ggVG'
  else
    -- LẦN 1: Vào Visual Block
    return '<C-v>'
  end
end, { expr = true, desc = 'V lần 1: Visual Block, lần 2: Select All' })

-- 2. Combo v -> vv -> vvv
vim.keymap.set('x', 'v', function()
  local curr_mode = vim.fn.mode()
  if curr_mode ~= 'v' and curr_mode ~= 'V' then return 'v' end

  local cursor_line = vim.fn.line('.')
  local anchor_line = vim.fn.line('v')
  local cur_col = vim.fn.col('.')
  local anc_col = vim.fn.col('v')
  
  -- Lấy thông tin dòng để kiểm tra độ phủ
  local line_content = vim.fn.getline('.')
  local line_len = #line_content
  local first_char_col = line_content:find('%S') or 1 -- Cột của ký tự đầu tiên (^ )

  -- KIỂM TRA CẤP ĐỘ:
  -- Check xem có đang ở trạng thái "Màu Xanh" (^ đến g_) không
  local is_blue_style = (cur_col == first_char_col or anc_col == first_char_col) 
                        and (cur_col >= line_len or anc_col >= line_len)

  if is_blue_style then
    -- CẤP ĐỘ 3: Sang "Màu Đỏ" (0 đến $)
    if cursor_line > anchor_line then return 'o0o$'
    elseif cursor_line < anchor_line then return '0o$o'
    else return '0o$' end
  else
    -- CẤP ĐỘ 2: Sang "Màu Xanh" (^ đến g_)
    if cursor_line > anchor_line then return 'o^og_'
    elseif cursor_line < anchor_line then return '^og_o'
    else return '^og_' end
  end
end, { expr = true, desc = 'v (normal) -> vv (blue) -> vvv (red)' })

-- Đảm bảo Space hoạt động bình thường, không chạy lệnh lạ
vim.keymap.set('n', '<Space>', 'a<Space><Esc>', { noremap = true, silent = true })

-- 1. Định nghĩa chuỗi ^[[2~ là phím <F13>
vim.cmd([[set <F13>=\<Esc>[2~]])

-- 2. Map <F13> cho Insert mode (không lùi con trỏ)
vim.keymap.set('i', '<F13>', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.cmd('stopinsert')
    vim.api.nvim_win_set_cursor(0, cursor)
end, { noremap = true, silent = true })

-- 3. Map cho các mode còn lại
vim.keymap.set({'n', 'v', 'x'}, '<F13>', '<Esc>', { noremap = true, silent = true })

vim.keymap.set({'n', 'v', 'i', 'x'}, '<D-v>', '<C-v>', { desc = 'Win + V for Visual Block' })
