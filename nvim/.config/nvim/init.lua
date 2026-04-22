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

vim.keymap.set('n', '<C-v>', '"+P', { desc = 'Paste Normal' })
vim.keymap.set('v', '<C-v>', '"_c<C-r>+<Esc>', { desc = 'Paste Visual' })
vim.keymap.set('i', '<C-v>', '<C-r>+', { desc = 'Paste Insert' })
vim.keymap.set('n', '<C-A-v>', '^vg_"+P', { noremap = true, silent = true })

vim.keymap.set({'n', 'i', 'v'}, '<C-z>', '<Cmd>undo<CR>', { desc = 'Undo' })
vim.keymap.set({'n', 'i', 'v'}, '<C-y>', '<Cmd>redo<CR>', { desc = 'Redo' })
vim.keymap.set({'n', 'i', 'v'}, '<C-f>', '<Esc>/', { desc = 'Search' })
vim.keymap.set({'n', 'i', 'v'}, '<C-s>', '<Cmd>w<CR>', { desc = 'Save file' })

-- ==========================================================================
-- 4. DI CHUYỂN & CHỈNH SỬA
-- ==========================================================================
vim.keymap.set('n', '<BS>', 'X', { desc = 'Backspace Normal' })
vim.keymap.set('v', '<BS>', 'x', { desc = 'Backspace Visual' })
vim.keymap.set({'n', 'v'}, '<S-BS>', 'Vd', { desc = "Xóa toàn bộ dòng" })
vim.keymap.set('v', '<Insert>', 'c')

vim.keymap.set('n', '<CR>', 'o<ESC>')
vim.keymap.set('n', '<S-CR>', 'O<ESC>')

vim.keymap.set("n", "<A-Up>", "<cmd>m .-2<cr>==")
vim.keymap.set("n", "<A-Down>", "<cmd>m .+1<cr>==")
vim.keymap.set("v", "<A-Up>", ":m '<-2<cr>gv=gv")
vim.keymap.set("v", "<A-Down>", ":m '>+1<cr>gv=gv")

vim.keymap.set({'n', 'v'}, '[', '<cmd>w<cr>')
vim.keymap.set({'n', 'v'}, '{', '<cmd>q!<cr>')
vim.keymap.set('n', ']', '<cmd>source $MYVIMRC<cr>')

vim.keymap.set('n', '<C-Home>', 'gg1|')
vim.keymap.set('i', '<C-Home>', '<C-O>gg<C-O>1|')
vim.keymap.set('n', '<C-End>', 'G$')
vim.keymap.set('i', '<C-End>', '<C-O>G<C-O>$')

vim.keymap.set('v', 'v', function()
  if vim.fn.mode() ~= 'v' then return "v" end

  local line_cur = vim.fn.line('.')
  local line_v = vim.fn.line('v')
  local col_cur = vim.fn.col('.')
  local col_v = vim.fn.getpos('v')[3]
  
  -- 1. Lấy thông tin dòng hiện tại
  local text = vim.fn.getline('.')
  local first = vim.fn.match(text, [[\S]]) + 1
  local last = vim.fn.strwidth((text:gsub("%s+$", "")))

  -- 2. Kiểm tra độ bao phủ (Coverage)
  -- Đối với bôi đen một dòng: col_cur và col_v phải bao trùm first và last
  -- Đối với bôi đen nhiều dòng: Nếu con trỏ ở dòng trên cùng thì nó phải <= first,
  -- nếu con trỏ ở dòng dưới cùng thì nó phải >= last.
  
  local is_smart_covered = false
  if line_cur == line_v then
    -- Trường hợp 1 dòng: Gốc và Ngọn phải bao trùm ^ và g_
    local min_c = math.min(col_cur, col_v)
    local max_c = math.max(col_cur, col_v)
    is_smart_covered = (min_c <= first) and (max_c >= last)
  else
    -- Trường hợp nhiều dòng (như bạn dùng chuột):
    -- Phải kiểm tra xem con trỏ hiện tại đã chạm biên tương ứng chưa
    if line_cur < line_v then
      -- Đang kéo ngược lên (như hình của bạn): Con trỏ phải ở đầu (<= first)
      is_smart_covered = (col_cur <= first)
    else
      -- Đang kéo xuôi xuống: Con trỏ phải ở cuối (>= last)
      is_smart_covered = (col_cur >= last)
    end
  end

  if is_smart_covered then
    -- LẦN 3: Nở ra 0 -> g_
    if line_cur >= line_v then return "o0og_" else return "og_o0" end
  else
    -- LẦN 2: Ép vào ^ -> g_
    if line_cur >= line_v then return "o^og_" else return "og_o^" end
  end
end, { expr = true, noremap = true })

-- ==========================================================================
-- 6. TIỆN ÍCH KHÁC
-- ==========================================================================
vim.keymap.set('n', '<Space>', 'a<Space><Esc>', { noremap = true, silent = true })
vim.keymap.set({'n', 'v', 'i', 'x'}, '<D-v>', '<C-v>', { desc = 'Visual Block' })

vim.keymap.set('i', '<Esc>', function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.cmd('stopinsert')
  vim.schedule(function() pcall(vim.api.nvim_win_set_cursor, 0, cursor) end)
end, { noremap = true, silent = true, desc = 'Esc đứng im' })
