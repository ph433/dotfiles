-- ==========================================================================
-- 2. ĐỊNH DẠNG FILE & ĐIỀU HƯỚNG CẤU HÌNH KANATA
-- ==========================================================================
vim.filetype.add({ extension = { kbd = "kanata" } })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "kanata",
  callback = function()
    vim.bo.commentstring = ";; %s"
  end,
})

-- Tự động lưu đường dẫn file vừa mở vào file log hệ thống
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("LogRecentFiles", { clear = true }),
  callback = function()
    -- Lấy đường dẫn tuyệt đối của file đang mở
    local file_path = vim.api.nvim_buf_get_name(0)
    -- Né đống file rác, file tạm, hoặc các giao diện như Netrw, Telescope
    if file_path == "" or file_path:match("toggleterm") or file_path:match("NvimTree") or vim.bo.buftype ~= "" then
      return
    end

    -- Khai báo file log nằm gọn trong thư mục cache
    local log_dir = vim.fn.expand("~/.cache/yazi/")
    vim.fn.mkdir(log_dir, "p") -- Tự tạo thư mục nếu chưa có
    local log_file = log_dir .. "file_recent.log"

    -- Đọc file log cũ để xử lý trùng lặp (đẩy file mới nhất lên đầu)
    local lines = {}
    local f = io.open(log_file, "r")
    if f then
      for line in f:lines() do
        if line ~= file_path then
          table.insert(lines, line)
        end
      end
      f:close()
    end

    -- Chèn file vừa mở vào vị trí đầu tiên
    table.insert(lines, 1, file_path)

    -- Giới hạn danh sách chỉ nhớ tối đa 100 file gần nhất cho nhẹ máy
    while #lines > 100 do
      table.remove(lines)
    end

    -- Ghi đè lại vào file log
    local f_write = io.open(log_file, "w")
    if f_write then
      for _, line in ipairs(lines) do
        f_write:write(line .. "\n")
      end
      f_write:close()
    end
  end,
})
