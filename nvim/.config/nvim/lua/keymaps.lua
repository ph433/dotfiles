local keymap = vim.keymap

-- ==========================================================================
-- 3. PHÍM TẮT HỆ THỐNG (WINDOWS-STYLE)
-- ==========================================================================
vim.keymap.set({'n', 'i', 'v'}, '<C-a>', '<Esc>ggVG', { desc = 'Select All' })
vim.keymap.set('v', '<C-c>', '"+y', { desc = 'Copy selection' })
vim.keymap.set('n', '<C-c>', '^vg_"+y', { noremap = true, silent = true })
vim.keymap.set({'n', 'v', 'i'}, '<D-C-c>', '<cmd>%y+<cr>', { noremap = true, silent = true })

-- vim.keymap.set('n', '<C-v>', '"+p', { desc = 'Paste Normal' })
vim.keymap.set('v', '<C-v>', '"_c<C-r>+<Esc>', { desc = 'Paste Visual' })
vim.keymap.set('i', '<C-v>', '<C-r>+', { desc = 'Paste Insert' })
vim.keymap.set('n', '<C-A-v>', '^vg_"+P', { noremap = true, silent = true })

vim.keymap.set({'n', 'i', 'v'}, '<C-z>', '<Cmd>undo<CR>', { desc = 'Undo' })
vim.keymap.set({'n', 'i', 'v'}, '<C-y>', '<Cmd>redo<CR>', { desc = 'Redo' })
vim.keymap.set({'n', 'i', 'v'}, '<C-f>', '<Esc>/', { desc = 'Search' })
-- vim.keymap.set({'n', 'i', 'v'}, '<C-s>', '<Cmd>w<CR>', { desc = 'Save file' })

-- Cuộn màn hình LÊN 1/4 trang
vim.keymap.set({'n', 'i', 'v'}, '<C-Up>', function()
  -- Lấy chiều cao cửa sổ chia cho 4 và làm tròn xuống
  local quarter_screen = math.floor(vim.api.nvim_win_get_height(0) / 8)
  local keys = vim.api.nvim_replace_termcodes(quarter_screen .. '<C-y>', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = "Cuộn màn hình lên 1/4 trang" })

-- Cuộn màn hình XUỐNG 1/4 trang
vim.keymap.set({'n', 'i', 'v'}, '<C-Down>', function()
  -- Lấy chiều cao cửa sổ chia cho 4 và làm tròn xuống
  local quarter_screen = math.floor(vim.api.nvim_win_get_height(0) / 8)
  local keys = vim.api.nvim_replace_termcodes(quarter_screen .. '<C-e>', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = "Cuộn màn hình xuống 1/4 trang" })

-- -- Cuộn xuống nửa trang bằng Ctrl + Mũi tên xuống
-- vim.keymap.set({'v'}, '<C-Down>', '<C-d>', { desc = 'Cuộn xuống nửa trang' })
--
-- -- Cuộn lên nửa trang bằng Ctrl + Mũi tên lên
-- vim.keymap.set({'v'}, '<C-Up>', '<C-u>', { desc = 'Cuộn lên nửa trang' })

-- -- Cuộn xuống 100% bằng cách gọi API (Bỏ qua việc <C-f> bị map đè)
-- vim.keymap.set({'n', 'v', 'i'}, '<D-Down>', function()
--     vim.cmd('normal! \x06') -- \x06 là mã hex gốc của Ctrl+f trong Vim, dấu ! để bỏ qua user map
-- end, { desc = 'Cuộn xuống toàn bộ trang' })
--
-- -- Cuộn lên 100% bằng cách gọi API (Tương tự cho Ctrl+b)
-- vim.keymap.set({'n', 'v', 'i'}, '<D-Up>', function()
--     vim.cmd('normal! \x02') -- \x02 là mã hex gốc của Ctrl+b trong Vim
-- end, { desc = 'Cuộn lên toàn bộ trang' })

-- Chế độ Insert và Command-line: Map trực tiếp sang <C-w> (Cực kỳ an toàn vì ở đây <C-w> không dính dáng tới Window)
vim.keymap.set({'i', 'c'}, '<C-BS>', '<C-w>', { desc = 'Xóa một từ phía trước' })

-- Chế độ Normal: Dùng lệnh "db" (delete backward) để xóa đích danh 1 từ từ vị trí con trỏ ngược về trước
vim.keymap.set('n', '<C-BS>', 'db', { desc = 'Xóa một từ phía trước' })

-- ==========================================================================
-- 4. DI CHUYỂN & CHỈNH SỬA
-- ==========================================================================
vim.keymap.set('n', '<BS>', 'X', { desc = 'Backspace Normal' })
vim.keymap.set('v', '<BS>', 'x', { desc = 'Backspace Visual' })
vim.keymap.set({'n', 'v'}, '<S-BS>', 'Vd', { desc = "Xóa toàn bộ dòng" })
vim.keymap.set('v', '<Insert>', 'c')
-- vim.keymap.set('n', '<D-Insert>', 'ciw', { noremap = true })

vim.keymap.set("n", "<A-Up>", "<cmd>m .-2<cr>==")
vim.keymap.set("n", "<A-Down>", "<cmd>m .+1<cr>==")
vim.keymap.set("v", "<A-Up>", ":m '<-2<cr>gv=gv")
vim.keymap.set("v", "<A-Down>", ":m '>+1<cr>gv=gv")

vim.keymap.set({'n', 'v'}, '[', '<cmd>w<cr>')
vim.keymap.set({'n', 'v'}, '{', '<cmd>q!<cr>')
vim.keymap.set({'n', 'v'}, "<A-ESC>", '<cmd>q<cr>')
vim.keymap.set('n', ']', '<cmd>source $MYVIMRC<cr>')

-- vim.keymap.set('v', '<Space>', 'a<Space><Esc>', { noremap = true, silent = true })
-- vim.keymap.set('v', '<Space>', [[<Esc>*v//e<CR>]], { noremap = true, silent = true })
vim.keymap.set('v', '<Space>', '*', { remap = true, silent = true })

vim.keymap.set('v', 'a', 'c', { noremap = true, silent = true })
-- vim.keymap.set('v', 'i', 'c', { noremap = true, silent = true })
vim.keymap.set('v', 'R', 'c<C-o>R', { noremap = true, silent = true })
vim.keymap.set({'n', 'v', 'i', 'x'}, '<A-a>', '<C-v>', { desc = 'Visual Block' })

-- Ctrl + Mũi tên trái để nhảy về đầu từ (b)
vim.keymap.set({'n', 'v'}, '<C-Left>', 'b', { noremap = true, silent = true })
vim.keymap.set({'n', 'v'}, '<C-Right>', 'e', { noremap = true, silent = true })

-- Chuyển focus bằng Alt + h/j/k/l (st nhận diện cực mượt)
vim.keymap.set("n", "<S-A-h>", "<C-w>h", { desc = "Focus left" })
vim.keymap.set("n", "<S-A-j>", "<C-w>j", { desc = "Focus down" })
vim.keymap.set("n", "<S-A-k>", "<C-w>k", { desc = "Focus up" })
vim.keymap.set("n", "<S-A-l>", "<C-w>l", { desc = "Focus right" })

-- Mở split mới bằng Ctrl + Alt + h/j/k/l
vim.keymap.set("n", "<C-A-h>", "<cmd>leftabove vsplit<cr>", { desc = "Open split left" })
vim.keymap.set("n", "<C-A-l>", "<cmd>rightbelow vsplit<cr>", { desc = "Open split right" })
vim.keymap.set("n", "<C-A-k>", "<cmd>leftabove split<cr>",   { desc = "Open split up" })
vim.keymap.set("n", "<C-A-j>", "<cmd>rightbelow split<cr>",  { desc = "Open split down" })
vim.keymap.set("n", "<ESC>", "<cmd>noh<cr>",  { desc = "Open split down" })

-- 1. Alt + o : Đóng tất cả trừ cửa sổ hiện tại (only)
vim.keymap.set("n", "<S-A-p>", "<cmd>only<cr>", { desc = "Close all but current" })

-- 2. Alt + = : Cân bằng lại kích thước tất cả cửa sổ
vim.keymap.set("n", "<S-A-e>", "<cmd>wincmd =<cr>", { desc = "Equalize windows" })

-- 3. Alt + x : Đóng duy nhất cửa sổ đang focus (close)
vim.keymap.set("n", "<S-A-x>", "<cmd>close<cr>", { desc = "Close current split" })

-- 4. Alt + r : Xoay vị trí các cửa sổ (Rotate)
vim.keymap.set("n", "<S-A-r>", "<cmd>wincmd r<cr>", { desc = "Rotate windows" })

-- 5. Alt + m : Tối đa hóa cửa sổ hiện tại (Maximize)
vim.keymap.set("n", "<S-A-m>", "<cmd>vertical resize | resize<cr>", { desc = "Maximize current split" })

vim.keymap.set('n', '<C-t>', ':vsplit<CR>', { noremap = true, silent = true, desc = "Mở cửa sổ dọc mới" })
vim.keymap.set('n', '<C-S-t>', ':split<CR>', { noremap = true, silent = true, desc = "Mở cửa sổ dọc mới" })
-- Đóng cửa sổ hiện tại
vim.keymap.set('n', '<C-w>', ':close<CR>', { noremap = true, silent = true, desc = "Đóng cửa sổ hiện tại" })
vim.keymap.set('n', '<C-S-w>', ':only<CR>', { noremap = true, silent = true, desc = "Giữ lại cửa sổ duy nhất" })

-- Ctrl + Home: Về đầu file và nhảy về đầu dòng (gg0)
vim.keymap.set({'n', 'v'}, '<C-Home>', 'gg0', { desc = 'Go to top of file and start of line' })

-- Ctrl + End: Xuống cuối file và nhảy đến cuối dòng (G$)
vim.keymap.set({'n', 'v'}, '<C-End>', 'G$', { desc = 'Go to bottom of file and end of line' })

-- Dành riêng cho Insert Mode
vim.keymap.set('i', '<C-Home>', '<C-O>gg0', { desc = 'Go to top of file and start of line' })
vim.keymap.set('i', '<C-End>', '<C-O>G$', { desc = 'Go to bottom of file and end of line' })

vim.keymap.set('n', 'o', function()
  -- 1. Lấy thụt lề của dòng hiện tại
  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^%s*")

  -- 2. Đưa nội dung clipboard vào một bảng (table)
  -- Bạn dùng '+' nếu muốn dán từ clipboard hệ thống (Ctrl+C bên ngoài)
  -- Hoặc dùng '"' nếu chỉ dán từ nội dung đã copy trong nvim
  local clipboard_content = vim.fn.getreg('+')
  
  -- 3. Chia nội dung clipboard thành từng dòng để dán
  local lines = vim.split(clipboard_content, "\n")

  -- 4. Thêm thụt lề vào từng dòng của nội dung dán
  for i, l in ipairs(lines) do
    lines[i] = indent .. l
  end

  -- 5. Chèn nội dung vào dưới dòng hiện tại (lệnh 'l' là below)
  -- con trỏ sẽ được đặt ở dòng cuối cùng của nội dung vừa dán
  vim.api.nvim_put(lines, 'l', true, true)
end, { noremap = true, silent = true })

vim.keymap.set('n', 'O', function()
  -- 1. Lấy mức thụt lề hiện tại của dòng
  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^%s*")

  -- 2. Thay thế dòng bằng nội dung clipboard
  -- Lấy nội dung từ thanh ghi hệ thống '+'
  local clipboard_content = vim.fn.getreg('+')
  
  -- Xóa dòng hiện tại và thay bằng (thụt lề + clipboard)
  vim.api.nvim_set_current_line(indent .. clipboard_content)
end, { desc = "Thay thế dòng giữ nguyên thụt lề" })

vim.keymap.set('n', '<CR>', function()
  -- 1. Lấy nội dung của dòng hiện tại
  local current_line = vim.api.nvim_get_current_line()
  
  -- 2. Trích xuất đúng phần khoảng trắng (thụt lề) ở đầu dòng
  local indent = current_line:match("^%s*") or ""
  
  -- 3. Lấy vị trí dòng hiện hành (row)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  
  -- 4. Tạo một dòng mới ngay bên dưới, chứa sẵn lượng khoảng trắng đã copy
  vim.api.nvim_buf_set_lines(0, row, row, false, { indent })
  
  -- 5. Di chuyển con trỏ xuống dòng mới, đặt ngay sau phần khoảng trắng đó
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
end, { silent = true, desc = 'Tạo dòng mới giữ nguyên thụt lề, không tự thêm comment' })

vim.keymap.set('n', '<S-CR>', function()
  -- 1. Lấy nội dung của dòng hiện tại
  local current_line = vim.api.nvim_get_current_line()
  
  -- 2. Trích xuất đúng phần khoảng trắng (thụt lề) ở đầu dòng
  local indent = current_line:match("^%s*") or ""
  
  -- 3. Lấy vị trí dòng hiện hành (1-based index)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  
  -- 4. Tạo một dòng mới ngay bên TRÊN (vị trí row - 1), chứa sẵn lượng khoảng trắng
  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { indent })
  
  -- 5. Di chuyển con trỏ lên dòng mới đó, đặt ngay sau phần khoảng trắng
  vim.api.nvim_win_set_cursor(0, { row, #indent })
end, { silent = true, desc = 'Tạo dòng mới ở trên giữ nguyên thụt lề, không tự thêm comment' })

-- local picker = require("custom.my_picker")
--
-- -- Map phím ':' chạy command history tự chế
-- vim.keymap.set("n", ":", picker.cmd_history, { desc = "Custom Cmd History" })
--
-- -- Map phím '/' chạy search history tự chế
-- vim.keymap.set("n", "/", picker.search_history, { desc = "Custom Search History" })
