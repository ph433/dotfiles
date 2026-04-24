-- ==========================================================================
-- 1. CẤU HÌNH CƠ BẢN
-- ==========================================================================
vim.opt.number = true           -- Hiển thị số dòng
vim.opt.relativenumber = true   -- Số dòng tương đối
vim.opt.mouse = 'a'             -- Bật chuột
vim.opt.ignorecase = true       -- Không phân biệt hoa thường khi tìm
vim.opt.smartcase = true        -- Tự nhận diện hoa thường nếu ta gõ chữ Hoa
vim.g.mapleader = ","           -- Phím Leader là dấu phẩy
vim.opt.clipboard = "unnamedplus" -- Clipboard hệ thống

-- ==========================================================================
-- 2. ĐỊNH DẠNG FILE & TỰ ĐỘNG HÓA
-- ==========================================================================
vim.filetype.add({ extension = { kbd = "lisp" } })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lisp",
  callback = function()
    vim.bo.commentstring = ";; %s"
  end,
})

-- ==========================================================================
-- 3. PHÍM TẮT HỆ THỐNG (WINDOWS-STYLE)
-- ==========================================================================
vim.keymap.set({'n', 'i', 'v'}, '<C-a>', '<Esc>ggVG', { desc = 'Select All' })
vim.keymap.set('v', '<C-c>', '"+y', { desc = 'Copy selection' })
vim.keymap.set('n', '<C-c>', '^vg_"+y', { noremap = true, silent = true })
vim.keymap.set({'n', 'v', 'i'}, '<D-C-c>', '<cmd>%y+<cr>', { noremap = true, silent = true })

vim.keymap.set('n', '<C-v>', '"+p', { desc = 'Paste Normal' })
vim.keymap.set('v', '<C-v>', '"_c<C-r>+<Esc>', { desc = 'Paste Visual' })
vim.keymap.set('i', '<C-v>', '<C-r>+', { desc = 'Paste Insert' })
vim.keymap.set('n', '<C-A-v>', '^vg_"+P', { noremap = true, silent = true })

vim.keymap.set({'n', 'i', 'v'}, '<C-z>', '<Cmd>undo<CR>', { desc = 'Undo' })
vim.keymap.set({'n', 'i', 'v'}, '<C-y>', '<Cmd>redo<CR>', { desc = 'Redo' })
vim.keymap.set({'n', 'i', 'v'}, '<C-f>', '<Esc>/', { desc = 'Search' })
-- vim.keymap.set({'n', 'i', 'v'}, '<C-s>', '<Cmd>w<CR>', { desc = 'Save file' })

-- ==========================================================================
-- 4. DI CHUYỂN & CHỈNH SỬA
-- ==========================================================================
vim.keymap.set('n', '<BS>', 'X', { desc = 'Backspace Normal' })
vim.keymap.set('v', '<BS>', 'x', { desc = 'Backspace Visual' })
vim.keymap.set({'n', 'v'}, '<S-BS>', 'Vd', { desc = "Xóa toàn bộ dòng" })
vim.keymap.set('v', '<Insert>', 'c')
-- vim.keymap.set('n', '<D-Insert>', 'ciw', { noremap = true })

vim.keymap.set('n', '<CR>', 'o<ESC>')
vim.keymap.set('n', '<S-CR>', 'O<ESC>')

vim.keymap.set("n", "<A-Up>", "<cmd>m .-2<cr>==")
vim.keymap.set("n", "<A-Down>", "<cmd>m .+1<cr>==")
vim.keymap.set("v", "<A-Up>", ":m '<-2<cr>gv=gv")
vim.keymap.set("v", "<A-Down>", ":m '>+1<cr>gv=gv")

vim.keymap.set({'n', 'v'}, '[', '<cmd>w<cr>')
vim.keymap.set({'n', 'v'}, '{', '<cmd>q!<cr>')
vim.keymap.set('n', ']', '<cmd>source $MYVIMRC<cr>')

-- Cấu hình cho phím v (chọn sát nội dung dùng ^ và g_)
vim.keymap.set("v", "v", function()
    local cursor_line = vim.fn.line(".")
    local anchor_line = vim.fn.line("v")
    -- Nếu đang ở Visual Line (V), nhấn v để về Visual thường trước khi chạy lệnh
    local prefix = vim.fn.mode() == "V" and "v" or ""

    if cursor_line >= anchor_line then
        return prefix .. "o^og_"
    else
        return prefix .. "og_o^"
    end
end, { expr = true, noremap = true })

-- Cấu hình cho phím V (chọn kịch biên dùng 0 và g_)
vim.keymap.set("v", "V", function()
    local cursor_line = vim.fn.line(".")
    local anchor_line = vim.fn.line("v")
    -- Ép về Visual thường để 0 và g_ có tác dụng
    local prefix = vim.fn.mode() == "V" and "v" or ""

    if cursor_line >= anchor_line then
        return prefix .. "o0og_"
    else
        return prefix .. "og_o0"
    end
end, { expr = true, noremap = true })

-- vim.keymap.set('v', 'v', function()
--   if vim.fn.mode() ~= 'v' then return "v" end
--
--   local cur_line = vim.fn.line('.')
--   local v_line = vim.fn.line('v')
--   local cur_col = vim.fn.virtcol('.')
--   local v_col = vim.fn.virtcol('v')
--
--   local text = vim.fn.getline('.')
--   local first_idx = vim.fn.match(text, [[\S]])
--   local first_vcol = (first_idx ~= -1) and vim.fn.virtcol({cur_line, first_idx + 1}) or 1
--   local last_vcol = vim.fn.virtcol({cur_line, #text:gsub("%s+$", "")})
--
--   if first_vcol > last_vcol then first_vcol = 1; last_vcol = 1 end
--
--   -- LOGIC MỚI: Kiểm tra độ rộng vùng chọn
--   -- Nếu bạn vừa từ dòng khác nhảy xuống, vùng chọn thường có độ rộng cột bằng 0 
--   -- (vì con trỏ đi thẳng xuống). Chúng ta cấm nấc 3 trong trường hợp này.
--   local selection_width = math.abs(cur_col - v_col)
--   local is_content_empty = (first_vcol == last_vcol)
--
--   local is_step2_done = false
--   if cur_line == v_line then
--     is_step2_done = (math.min(cur_col, v_col) <= first_vcol) and (math.max(cur_col, v_col) >= last_vcol) 
--                     and (selection_width > 0 or is_content_empty)
--   else
--     -- ĐA DÒNG: 
--     -- Chỉ cho phép nấc 3 nếu vùng chọn ĐÃ có độ rộng (tức là đã thực hiện hít vào ^ hoặc g_ trước đó)
--     -- hoặc nếu con trỏ đang đứng chính xác ở biên và vùng chọn không phải một đường thẳng đứng
--     if cur_line < v_line then
--       is_step2_done = (cur_col == first_vcol) and (selection_width > 0)
--     else
--       is_step2_done = (cur_col == last_vcol) and (selection_width > 0)
--     end
--   end
--
--   if is_step2_done then
--     -- LẦN 3: Bung ra biên 0
--     if cur_line < v_line then return "og_o0"
--     elseif cur_line > v_line then return "o0og_"
--     else return "0og_" end
--   else
--     -- LẦN 2: Ép vào nội dung (Trị lỗi nhảy cóc)
--     if cur_line < v_line then return "og_o^"
--     elseif cur_line > v_line then return "o^og_"
--     else return "^og_" end
--   end
-- end, { expr = true, noremap = true })

-- ==========================================================================
-- 6. TIỆN ÍCH KHÁC
-- ==========================================================================
vim.keymap.set('n', '<Space>', 'a<Space><Esc>', { noremap = true, silent = true })

vim.keymap.set('v', 'a', 'c', { noremap = true, silent = true })
-- vim.keymap.set('v', 'i', 'c', { noremap = true, silent = true })
vim.keymap.set('v', 'R', 'c<C-o>R', { noremap = true, silent = true })
vim.keymap.set({'n', 'v', 'i', 'x'}, '<D-v>', '<C-v>', { desc = 'Visual Block' })

-- vim.keymap.set('i', '<Esc>', function()
--   local cursor = vim.api.nvim_win_get_cursor(0)
--   vim.cmd('stopinsert')
--   vim.schedule(function() pcall(vim.api.nvim_win_set_cursor, 0, cursor) end)
-- end, { noremap = true, silent = true, desc = 'Esc đứng im' })

-- Ctrl + Mũi tên trái để nhảy về đầu từ (b)
vim.keymap.set({'n', 'v'}, '<C-Left>', 'b', { noremap = true, silent = true })
vim.keymap.set({'n', 'v'}, '<C-Right>', 'e', { noremap = true, silent = true })

local opts = { noremap = true, silent = true }

-- Hàm xử lý tìm kiếm thông minh: Không dấu, không hoa thường, tự quay đầu
local function smart_move(char, forward)
  if not char or char == "" then return end

  -- Fix lỗi Syntax: Sử dụng dấu ngoặc kép để nối chuỗi pattern
  -- Kết quả pattern sẽ có dạng: \c[[=a=]]
  local pattern = "\\c[[=" .. char .. "=]]"
  
  -- Lấy vị trí hiện tại của dòng
  local stop_line = vim.fn.line('.')
  
  -- Thử tìm ký tự tiếp theo (W: không tự wrap của Vim để mình tự xử lý biên)
  local flags = forward and "W" or "bW"
  local found = vim.fn.search(pattern, flags, stop_line)

  -- Nếu không tìm thấy (đã chạm biên), thực hiện nhảy về biên xa nhất (Wrap thủ công)
  if found == 0 then
    if forward then
      -- Đang đi tới mà hết: Nhảy về đầu dòng (cột 1) rồi tìm tiếp
      vim.fn.cursor(stop_line, 1)
    else
      -- Đang đi lùi mà hết: Nhảy về cuối dòng rồi tìm ngược lại
      vim.fn.cursor(stop_line, vim.fn.col('$'))
    end
    -- Thực hiện tìm kiếm lần nữa từ biên mới
    vim.fn.search(pattern, flags, stop_line)
  end

  -- Lưu lại ký tự đã gõ để phím ; và , có thể dùng lại
  vim.fn.setcharsearch({ char = char, forward = (forward and 1 or 0), type = 'f' })
end

-- --- MAP PHÍM ---

-- f: Tìm xuôi (không phân biệt hoa thường/dấu)
vim.keymap.set({'n', 'x', 'o'}, 'f', function()
  local char = vim.fn.getcharstr()
  smart_move(char, true)
end, opts)

-- F: Tìm ngược (không phân biệt hoa thường/dấu)
vim.keymap.set({'n', 'x', 'o'}, 'F', function()
  local char = vim.fn.getcharstr()
  smart_move(char, false)
end, opts)

-- ; : LUÔN LUÔN nhảy TỚI (Sang phải)
vim.keymap.set({'n', 'x', 'o'}, ';', function()
  local res = vim.fn.getcharsearch()
  if res and res.char and res.char ~= "" then 
    smart_move(res.char, true) 
  end
end, opts)

-- , : LUÔN LUÔN nhảy LUI (Sang trái)
vim.keymap.set({'n', 'x', 'o'}, ',', function()
  local res = vim.fn.getcharsearch()
  if res and res.char and res.char ~= "" then 
    smart_move(res.char, false) 
  end
end, opts)

-- -- Chuyển focus bằng Windows + Phím mũi tên
-- vim.keymap.set("n", "<D-Left>",  "<C-w>h", { desc = "Focus left" })
-- vim.keymap.set("n", "<D-Down>",  "<C-w>j", { desc = "Focus down" })
-- vim.keymap.set("n", "<D-Up>",    "<C-w>k", { desc = "Focus up" })
-- vim.keymap.set("n", "<D-Right>", "<C-w>l", { desc = "Focus right" })

-- Chuyển focus bằng Alt + Shift + Win + Phím mũi tên
vim.keymap.set("n", "<A-S-D-Left>",  "<C-w>h", { desc = "Focus left" })
vim.keymap.set("n", "<A-S-D-Down>",  "<C-w>j", { desc = "Focus down" })
vim.keymap.set("n", "<A-S-D-Up>",    "<C-w>k", { desc = "Focus up" })
vim.keymap.set("n", "<A-S-D-Right>", "<C-w>l", { desc = "Focus right" })

local key = vim.keymap.set

-- Ctrl + Alt + Shift + Win + Mũi tên: Mở split mới theo hướng đó
key("n", "<C-A-S-D-Left>",  "<cmd>leftabove vsplit<cr>", { desc = "Open split left" })
key("n", "<C-A-S-D-Right>", "<cmd>rightbelow vsplit<cr>", { desc = "Open split right" })
key("n", "<C-A-S-D-Up>",    "<cmd>leftabove split<cr>",   { desc = "Open split up" })
key("n", "<C-A-S-D-Down>",  "<cmd>rightbelow split<cr>",  { desc = "Open split down" })

-- Ctrl + Alt + Shift + Win + O: Đóng tất cả trừ cửa sổ hiện tại
vim.keymap.set("n", "<C-A-S-D-o>", "<cmd>only<cr>", { desc = "Close all but current" })
