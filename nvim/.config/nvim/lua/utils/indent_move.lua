local M = {}

---So khớp và cộng dồn thụt đầu dòng (indent) sang các dòng tiếp theo
---@param direction "up"|"down"
function M.match_indent_and_move(direction)
  local count = vim.v.count1

  -- 1. Lấy độ dài lề dòng 0 (dòng hiện tại)
  local line0_text = vim.api.nvim_get_current_line()
  local indent0_str = line0_text:match("^(%s*)") or ""
  local indent0_len = #indent0_str

  local step = (direction == "down") and 1 or -1
  local start_line = vim.fn.line(".")
  local total_lines = vim.fn.line("$")
  local target_line = start_line
  local found_count = 0
  local indent1_len = 0 -- Độ dài lề gốc của dòng 1 (dòng khác rỗng đầu tiên)

  -- 2. Duyệt qua các dòng
  while found_count < count do
    target_line = target_line + step

    if target_line < 1 or target_line > total_lines then
      vim.notify("Đã chạm mốc đầu/cuối file!", vim.log.levels.WARN)
      break
    end

    local line_content = vim.api.nvim_buf_get_lines(0, target_line - 1, target_line, false)[1]

    -- Chỉ xử lý dòng khác rỗng
    if line_content:match("%S") then
      found_count = found_count + 1
      local orig_indent = line_content:match("^(%s*)") or ""
      local new_indent_str = ""

      if found_count == 1 then
        -- Dòng 1: Ghi nhớ độ dài lề gốc N1, thay bằng lề dòng 0 (N0)
        indent1_len = #orig_indent
        new_indent_str = indent0_str
      else
        -- Dòng 2 trở đi: Lấy (N_i - N_1) + N_0
        local diff = #orig_indent - indent1_len
        local final_indent_len = math.max(0, indent0_len + diff)
        new_indent_str = string.rep(" ", final_indent_len)
      end

      -- Cập nhật dòng vào buffer
      local new_line_text = line_content:gsub("^%s*", new_indent_str)
      vim.api.nvim_buf_set_lines(0, target_line - 1, target_line, false, { new_line_text })
    end
  end

  -- 3. Di chuyển con trỏ tới dòng mục tiêu
  if target_line >= 1 and target_line <= total_lines then
    vim.api.nvim_win_set_cursor(0, { target_line, 0 })
  end
end

---Bắt phím điều hướng j/k hoặc phím mũi tên Up/Down
function M.start_indent_map()
  local ok, char_code = pcall(vim.fn.getchar)
  if not ok then return end

  local key = (type(char_code) == "number") and vim.fn.nr2char(char_code) or char_code

  local key_down = vim.keycode and vim.keycode("<Down>") or vim.api.nvim_replace_termcodes("<Down>", true, true, true)
  local key_up   = vim.keycode and vim.keycode("<Up>")   or vim.api.nvim_replace_termcodes("<Up>", true, true, true)

  if key == "j" or key == key_down then
    M.match_indent_and_move("down")
  elseif key == "k" or key == key_up then
    M.match_indent_and_move("up")
  else
    vim.cmd("redraw")
  end
end

---Cấu hình keymap mặc định (tùy chọn)
---@param lhs? string Phím kích hoạt (mặc định là "=")
---@param opts? table Các tùy chọn bổ sung cho vim.keymap.set
function M.setup(lhs, opts)
  lhs = lhs or "="
  opts = vim.tbl_deep_extend("force", {
    expr = false,
    silent = true,
    desc = "Copy và cộng dồn indent sang các dòng tiếp theo",
  }, opts or {})

  vim.keymap.set("n", lhs, M.start_indent_map, opts)
end

return M
