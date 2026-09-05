local M = {}

function M.paste_with_indent(reg)
  reg = reg or '+'
  local text = vim.fn.getreg(reg)
  if text == '' then return end

  local current_line = vim.api.nvim_get_current_line()
  local indent = current_line:match('^(%s*)') or ''
  local lines = vim.split(text, '\n', { plain = true })

  while #lines > 0 and lines[1]:match('^%s*$') do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines]:match('^%s*$') do
    table.remove(lines, #lines)
  end

  if #lines == 0 then return end

  local min_indent = nil
  for _, line in ipairs(lines) do
    if not line:match('^%s*$') then
      local lead_spaces = #(line:match('^(%s*)') or '')
      if not min_indent or lead_spaces < min_indent then
        min_indent = lead_spaces
      end
    end
  end
  min_indent = min_indent or 0

  local formatted_lines = {}
  for _, line in ipairs(lines) do
    if line:match('^%s*$') then
      table.insert(formatted_lines, '')
    else
      local stripped = line:sub(min_indent + 1)
      table.insert(formatted_lines, indent .. stripped)
    end
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, formatted_lines)
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
end

return M
