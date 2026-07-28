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

-- vim.keymap.set('i', '<Esc>', function()
--   local cursor = vim.api.nvim_win_get_cursor(0)
--   vim.cmd('stopinsert')
--   vim.schedule(function() pcall(vim.api.nvim_win_set_cursor, 0, cursor) end)
-- end, { noremap = true, silent = true, desc = 'Esc đứng im' })


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


-- Map phím * để tìm nội dung đang có trong Clipboard
vim.keymap.set('n', '*', function()
  -- Lấy nội dung từ clipboard hệ thống
  local clipboard_content = vim.fn.getreg('+')
  
  -- Thoát các ký tự đặc biệt để không làm lỗi Regex của Vim
  local escaped_content = vim.fn.escape(clipboard_content, '\\/.*$^~[]')
  
  -- Thực hiện lệnh tìm kiếm: / nội dung /
  -- <CR> để thực thi ngay, nếu muốn sửa lại trước khi tìm thì bỏ <CR>
  vim.cmd('/' .. escaped_content)
end, { noremap = true, silent = false, desc = "Tìm kiếm nội dung từ clipboard" })

-- Biến cục bộ để lưu trữ tạm thời dòng gốc và lề của nó
local anchor_row = 0
local anchor_indent = ""

-- Hàm căn lề: Lấy dòng KHÔNG RỖNG đầu tiên chạm vào làm mốc để bằng dòng Anchor
function _G.AlignBlockByFirstNonBlank(type)
  local start_line = vim.api.nvim_buf_get_mark(0, "[")[1]
  local end_line = vim.api.nvim_buf_get_mark(0, "]")[1]

  if start_line == 0 or end_line == 0 or start_line >= end_line then return end

  -- 1. Lấy lề của dòng mốc (Anchor - Dòng start_line)
  local anchor_content = vim.fn.getline(start_line)
  local anchor_indent_str = string.match(anchor_content, "^%s*") or ""
  local anchor_indent_len = #anchor_indent_str

  -- 2. Đọc tất cả các dòng trong vùng chọn
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines < 2 then return end

  -- 3. Tìm dòng KHÔNG RỖNG đầu tiên từ dòng thứ 2 trở đi
  local target_indent_len = nil
  for i = 2, #lines do
    if lines[i]:match("%S") then -- Tìm dòng có chữ/ký tự
      target_indent_len = #(string.match(lines[i], "^%s*") or "")
      break
    end
  end

  -- Nếu tất cả các dòng bên dưới đều rỗng thì không làm gì cả
  if not target_indent_len then return end

  -- 4. Tính độ lệch tịnh tiến dựa trên dòng không rỗng đầu tiên đó
  local shift_delta = anchor_indent_len - target_indent_len

  -- 5. Cập nhật lề cho toàn bộ khối
  local new_lines = { lines[1] } -- Dòng mốc (Anchor) giữ nguyên

  for i = 2, #lines do
    local line = lines[i]
    if not line:match("%S") then
      -- Dòng rỗng giữ nguyên không thêm/bớt space
      table.insert(new_lines, line)
    else
      local current_indent_len = #(string.match(line, "^%s*") or "")
      local new_indent_len = math.max(0, current_indent_len + shift_delta)
      local trimmed_line = line:gsub("^%s*", "")
      table.insert(new_lines, string.rep(" ", new_indent_len) .. trimmed_line)
    end
  end

  -- Cập nhật lại buffer
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
end

-- Keymap Smart Esc
vim.keymap.set('n', '<Esc>', function()
  if vim.v.hlsearch == 1 then
    vim.cmd("nohlsearch")
  else
    vim.go.operatorfunc = "v:lua.AlignBlockByFirstNonBlank"
    return "g@"
  end
end, { expr = true, silent = true, desc = "Smart Esc: Align block by first non-blank line" })

vim.keymap.set('n', '<Tab>', function()
  if vim.v.hlsearch == 1 then
    local pattern = vim.fn.getreg('/')

    -- Kiểm tra nếu chưa được bọc bằng Negative Lookahead @!
    if not pattern:find('@!') then
      -- 1. Xóa sạch tất cả các flag magic (\v, \V), boundary (\c, \<, \>) do * hoặc / tạo ra
      local clean = pattern
        :gsub('\\[vV]', '')
        :gsub('\\<', '')
        :gsub('\\>', '')
        :gsub('^%(', '')
        :gsub('%)', '')

      -- 2. Tạo pattern Very Magic mới không bị dính gạch ngang/dưới/chữ/số phía sau
      local exact_pattern = '\\v<(' .. clean .. ')>([a-zA-Z0-9_-])@!'
      vim.fn.setreg('/', exact_pattern)
    end

    -- 3. Nhảy tới kết quả tiếp theo
    pcall(vim.cmd, 'normal! n')
  else
    -- Nếu không có hlsearch, bấm Tab trả về chức năng mặc định
    local tab_key = vim.api.nvim_replace_termcodes('<Tab>', true, false, true)
    vim.api.nvim_feedkeys(tab_key, 'n', false)
  end
end, { desc = 'Strict exact search on Tab' })
