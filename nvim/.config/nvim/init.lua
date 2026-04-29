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

--- 1. HÀM TRỢ GIÚP ---

local function get_distance_cost(l1, c1, l2, c2)
  return math.abs(l1 - l2) * 1000 + math.abs(c1 - c2)
end

--- 2. CÁC HÀM XỬ LÝ CHÍNH ---

-- DỌC: Tìm tới đầu dòng chứa ký tự (Cho < > và khi dòng chỉ có 1 ký tự)
local function move_vertical_start(char, forward)
  if not char or char == "" then return end
  local pattern = "\\c[[=" .. char .. "=]]"
  local current_line = vim.fn.line('.')
  
  -- Nhảy ra khỏi ranh giới dòng hiện tại để tìm dòng khác
  vim.fn.cursor(current_line, forward and vim.fn.col('$') or 1)
  
  local flags = forward and "w" or "bw"
  local found = vim.fn.search(pattern, flags)
  
  -- Nếu vẫn dính ở dòng cũ, ép tìm tiếp dòng khác
  if found ~= 0 and vim.fn.line('.') == current_line then
    found = vim.fn.search(pattern, flags)
  end

  if found ~= 0 then
    local new_line = vim.fn.line('.')
    vim.fn.cursor(new_line, 1)
    vim.fn.search(pattern, "W", new_line)
    return true
  end
  return false
end

-- NGANG: Tìm trong dòng (Có biên, chỉ nhảy dòng nếu duy nhất 1 ký tự)
local function move_in_line_with_border(char, forward)
  if not char or char == "" then return end
  local pattern = "\\c[[=" .. char .. "=]]"
  local start_pos = vim.fn.getpos('.')
  local stop_line = vim.fn.line('.')
  local flags = forward and "W" or "bW"
  
  -- Bước 1: Thử tìm ký tự TIẾP THEO trong dòng (không wrap)
  -- Không dùng flag 'c' ở đây để đảm bảo nó phải di chuyển sang vị trí mới
  local found = vim.fn.search(pattern, flags, stop_line)
  
  -- Bước 2: Nếu không tìm thấy (đã chạm biên dòng)
  if found == 0 then
    -- Nhảy về biên đối diện
    vim.fn.cursor(stop_line, forward and 1 or vim.fn.col('$'))
    
    -- Bước 3: Tìm lại từ biên (Dùng flag 'c' để kiểm tra ngay tại vị trí vừa nhảy tới)
    local wrap_found = vim.fn.search(pattern, flags .. "c", stop_line)
    
    -- Bước 4: Kiểm tra xem có bị kẹt không
    -- Nếu tìm thấy mà vị trí vẫn trùng start_pos -> Cả dòng chỉ có DUY NHẤT 1 ký tự này
    if wrap_found ~= 0 and vim.fn.col('.') == start_pos[3] then
      move_vertical_start(char, forward)
    elseif wrap_found == 0 then
      -- Nếu nhảy biên rồi mà vẫn không thấy (trường hợp hy hữu), nhảy dọc luôn
      move_vertical_start(char, forward)
    end
  end
end

-- GẦN NHẤT (f)
local function move_to_closest(char)
  if not char or char == "" then return end
  local pattern = "\\c[[=" .. char .. "=]]"
  local cur_pos = vim.fn.getpos('.')
  local cur_l, cur_c = cur_pos[2], cur_pos[3]

  local b_pos = vim.fn.searchpos(pattern, "bnw")
  local f_pos = vim.fn.searchpos(pattern, "nw")

  local target = nil
  if b_pos[1] > 0 and f_pos[1] > 0 then
    local d_b = get_distance_cost(cur_l, cur_c, b_pos[1], b_pos[2])
    local d_f = get_distance_cost(cur_l, cur_c, f_pos[1], f_pos[2])
    target = (d_b < d_f) and b_pos or f_pos
  elseif b_pos[1] > 0 then target = b_pos
  elseif f_pos[1] > 0 then target = f_pos
  end

  if target then
    vim.fn.cursor(target[1], target[2])
    vim.fn.setcharsearch({ char = char, forward = 1, type = 'f' })
  end
end

--- 3. MAP PHÍM ---

vim.keymap.set({'n', 'x', 'o'}, 'f', function()
  local char = vim.fn.getcharstr()
  if char == "" or char:match('%s') then return end
  move_to_closest(char)
end, opts)

vim.keymap.set({'n', 'x', 'o'}, 'F', function()
  local char = vim.fn.getcharstr()
  if char == "" or char:match('%s') then return end
  move_to_closest(char)
end, opts)

-- ; : Ngang tới (Quay đầu trong dòng, nếu dòng có đúng 1 chữ thì mới nhảy xuống)
vim.keymap.set({'n', 'x', 'o'}, ';', function()
  local res = vim.fn.getcharsearch()
  if res and res.char ~= "" then move_in_line_with_border(res.char, true) end
end, opts)

-- , : Ngang lui (Quay đầu trong dòng, nếu dòng có đúng 1 chữ thì mới nhảy lên)
vim.keymap.set({'n', 'x', 'o'}, ',', function()
  local res = vim.fn.getcharsearch()
  if res and res.char ~= "" then move_in_line_with_border(res.char, false) end
end, opts)

-- > < : Nhảy dọc thuần túy (Luôn nhảy sang dòng khác)
vim.keymap.set({'n', 'x', 'o'}, '>', function()
  local res = vim.fn.getcharsearch()
  if res and res.char ~= "" then move_vertical_start(res.char, true) end
end, opts)

vim.keymap.set({'n', 'x', 'o'}, '<', function()
  local res = vim.fn.getcharsearch()
  if res and res.char ~= "" then move_vertical_start(res.char, false) end
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

-- 1. Ctrl-Alt-Shift-Win + '=' : Cân bằng lại tất cả cửa sổ (rất cần sau khi resize lung tung)
key("n", "<C-A-S-D-=>", "<cmd>wincmd =<cr>", { desc = "Equalize windows" })

-- 2. Ctrl-Alt-Shift-Win + 'x' : Đóng duy nhất cửa sổ đang focus
key("n", "<C-A-S-D-x>", "<cmd>close<cr>", { desc = "Close current split" })

-- 3. Ctrl-Alt-Shift-Win + 'r' : Xoay vị trí các cửa sổ (Rotate)
key("n", "<C-A-S-D-r>", "<cmd>wincmd r<cr>", { desc = "Rotate windows" })

-- 4. Tối đa hóa cửa sổ hiện tại (về chiều ngang hoặc dọc)
key("n", "<C-A-S-D-m>", "<cmd>vertical resize | resize<cr>", { desc = "Maximize current split" })
