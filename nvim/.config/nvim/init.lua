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

  local cur_line = vim.fn.line('.')
  local v_line = vim.fn.line('v')
  local cur_col = vim.fn.virtcol('.')
  local v_col = vim.fn.virtcol('v')

  local text = vim.fn.getline('.')
  local first_idx = vim.fn.match(text, [[\S]])
  local first_vcol = (first_idx ~= -1) and vim.fn.virtcol({cur_line, first_idx + 1}) or 1
  local last_vcol = vim.fn.virtcol({cur_line, #text:gsub("%s+$", "")})

  if first_vcol > last_vcol then first_vcol = 1; last_vcol = 1 end

  -- LOGIC MỚI: Kiểm tra độ rộng vùng chọn
  -- Nếu bạn vừa từ dòng khác nhảy xuống, vùng chọn thường có độ rộng cột bằng 0 
  -- (vì con trỏ đi thẳng xuống). Chúng ta cấm nấc 3 trong trường hợp này.
  local selection_width = math.abs(cur_col - v_col)
  local is_content_empty = (first_vcol == last_vcol)
  
  local is_step2_done = false
  if cur_line == v_line then
    is_step2_done = (math.min(cur_col, v_col) <= first_vcol) and (math.max(cur_col, v_col) >= last_vcol) 
                    and (selection_width > 0 or is_content_empty)
  else
    -- ĐA DÒNG: 
    -- Chỉ cho phép nấc 3 nếu vùng chọn ĐÃ có độ rộng (tức là đã thực hiện hít vào ^ hoặc g_ trước đó)
    -- hoặc nếu con trỏ đang đứng chính xác ở biên và vùng chọn không phải một đường thẳng đứng
    if cur_line < v_line then
      is_step2_done = (cur_col == first_vcol) and (selection_width > 0)
    else
      is_step2_done = (cur_col == last_vcol) and (selection_width > 0)
    end
  end

  if is_step2_done then
    -- LẦN 3: Bung ra biên 0
    if cur_line < v_line then return "og_o0"
    elseif cur_line > v_line then return "o0og_"
    else return "0og_" end
  else
    -- LẦN 2: Ép vào nội dung (Trị lỗi nhảy cóc)
    if cur_line < v_line then return "og_o^"
    elseif cur_line > v_line then return "o^og_"
    else return "^og_" end
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
