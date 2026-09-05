local M = {}

function M.paste_with_indent(reg)
  reg = reg or '+'
  local text = vim.fn.getreg(reg)
  if text == '' then return end

  -- 1. Dọn dẹp khoảng trắng rác từ trình duyệt
  -- Đổi Non-breaking space (NBSP) thành space thường và Tab thành 4 spaces
  text = text:gsub('[\194][\160]', ' '):gsub('\t', '    '):gsub('\r', '')
  local lines = vim.split(text, '\n', { plain = true })

  -- 2. Xóa các dòng trống dư thừa ở đầu và cuối
  while #lines > 0 and lines[1]:match('^%s*$') do table.remove(lines, 1) end
  while #lines > 0 and lines[#lines]:match('^%s*$') do table.remove(lines, #lines) end
  if #lines == 0 then return end

  -- 3. Tìm lề chuẩn bằng cách quét các dòng trong PHẦN THÂN (bỏ qua dòng 1)
  local min_body_indent = nil
  for i = 2, #lines do
    if not lines[i]:match('^%s*$') then
      local lead = #(lines[i]:match('^(%s*)'))
      if not min_body_indent or lead < min_body_indent then
        min_body_indent = lead
      end
    end
  end
  
  -- Fallback nếu copy đúng 1 dòng
  if not min_body_indent then
    min_body_indent = #(lines[1]:match('^(%s*)'))
  end

  local current_line = vim.api.nvim_get_current_line()
  local base_indent = current_line:match('^(%s*)') or ''
  local formatted_lines = {}

  -- 4. Ép lề tương đối vào cấu trúc mới
  for i, line in ipairs(lines) do
    if line:match('^%s*$') then
      table.insert(formatted_lines, '')
    else
      local cur_lead = #(line:match('^(%s*)'))
      local content = line:match('^%s*(.*)')
      
      local relative = 0
      
      -- [CHÌA KHÓA]: Nếu dòng 1 bị hụt lề do kéo chuột thiếu, đưa nó về lề gốc 0
      if i == 1 and cur_lead < min_body_indent then
        relative = 0
      else
        relative = cur_lead - min_body_indent
      end
      
      if relative < 0 then relative = 0 end
      table.insert(formatted_lines, base_indent .. string.rep(' ', relative) .. content)
    end
  end

  -- 5. Dán vào Neovim tại vị trí hiện tại
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if current_line:match('^%s*$') then
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, formatted_lines)
    vim.api.nvim_win_set_cursor(0, { row + #formatted_lines - 1, #base_indent })
  else
    vim.api.nvim_buf_set_lines(0, row, row, false, formatted_lines)
    vim.api.nvim_win_set_cursor(0, { row + #formatted_lines, #base_indent })
  end
end

return M
