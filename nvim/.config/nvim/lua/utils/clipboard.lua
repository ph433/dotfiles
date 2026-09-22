local M = {}

---Paste nội dung từ register xuống bên dưới dòng hiện tại:
---Toàn bộ khối code sẽ bám theo target_indent, đồng thời giữ nguyên vẹn
---tỷ lệ thụt lề tương quan giữa dòng 1 và các dòng bên dưới.
---@param reg? string Register cần lấy nội dung (mặc định là '*')
function M.paste_below_with_indent(reg)
  reg = reg or "+"

  -- 1. Lấy indent của dòng hiện tại làm đích
  local cur_line = vim.api.nvim_get_current_line()
  local target_indent = cur_line:match("^%s*") or ""

  -- 2. Lấy danh sách dòng từ register
  local lines = vim.fn.getreg(reg, 1, true)
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    return
  end

  -- 3. Xác định indent cơ sở của dòng 1 làm mốc
  local base_indent = lines[1]:match("^%s*") or ""
  local base_len = #base_indent

  -- 4. Điều chỉnh indent từng dòng theo tỷ lệ tương quan
  local adjusted_lines = {}
  for _, line in ipairs(lines) do
    if not line:match("%S") then
      -- Giữ nguyên dòng trống
      table.insert(adjusted_lines, "")
    else
      local line_indent = line:match("^%s*") or ""
      local stripped = line:sub(#line_indent + 1)

      -- Nếu dòng này thụt sâu hơn dòng 1: giữ lại phần chênh lệch
      if #line_indent >= base_len then
        local relative_indent = line_indent:sub(base_len + 1)
        table.insert(adjusted_lines, target_indent .. relative_indent .. stripped)
      else
        -- Nếu dòng này thụt ít hơn dòng 1: bám thẳng vào target_indent
        table.insert(adjusted_lines, target_indent .. stripped)
      end
    end
  end

  -- 5. Paste xuống dưới và đặt con trỏ vào đầu khối
  vim.api.nvim_put(adjusted_lines, "l", true, true)
end

return M
