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

-- Tự động chấm điểm frecency và lưu vào log (Bản fix chặn spam focus)
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("LogRecentFiles", { clear = true }),
  callback = function()
    -- Cơ chế chặn spam: Nếu cửa sổ này đã tính điểm cho file này rồi thì bỏ qua
    if vim.w.frecency_logged then
      return
    end

    local file_path = vim.api.nvim_buf_get_name(0)
    
    -- Né đống file rác, file tạm, log, hoặc giao diện
    if file_path == "" 
       or file_path:match("toggleterm") 
       or file_path:match("NvimTree") 
       or vim.bo.buftype ~= "" then
      return
    end

    -- ĐOẠN MỚI THÊM: Giải mã Symlink (Stow)
    -- Hàm này ép Neovim quy đổi mọi đường dẫn ảo (như ~/.config/...) 
    -- về chung một cái gốc vật lý (như ~/dotfiles/...)
    local real_path = vim.loop.fs_realpath(file_path)
    if real_path then
        file_path = real_path
    end

    -- Đánh dấu cửa sổ hiện tại đã log file này...
    vim.w.frecency_logged = true

    local log_dir = vim.fn.expand("~/.cache/yazi/")
    vim.fn.mkdir(log_dir, "p")
    local log_file = log_dir .. "file_recent.log"

    -- Đọc file log cũ và nạp vào bảng dữ liệu
    local files_score = {}
    local f = io.open(log_file, "r")
    if f then
      for line in f:lines() do
        -- Sửa pattern thành %S+ để hốt trọn gói (bất kể chấm hay phẩy)
        local score, path = line:match("^(%S+)%s+(.+)$")
        if score and path then
          -- Ép đổi dấu phẩy thành chấm (nếu có) trước khi cho Lua đọc số
          score = score:gsub(",", ".")
          files_score[path] = tonumber(score)
        end
      end
      f:close()
    end

    -- 1. Cập nhật điểm cho file hiện tại (Chỉ cộng khi thực sự mở)
    if files_score[file_path] then
      files_score[file_path] = files_score[file_path] + 10 
    else
      files_score[file_path] = 10 
    end

    -- 2. Cơ chế Giảm Điểm (Decay): Chỉ trừ điểm khi thực sự mở một file khác hẳn
    for path, score in pairs(files_score) do
      if path ~= file_path then
        files_score[path] = math.max(1.0, score - 1)
      end
    end

    -- 3. Sắp xếp theo điểm từ cao xuống thấp
    local sorted_list = {}
    for path, score in pairs(files_score) do
      table.insert(sorted_list, { path = path, score = score })
    end
    table.sort(sorted_list, function(a, b) return a.score > b.score end)

    -- 4. Giới hạn lưu tối đa 100 file
    while #sorted_list > 100 do
      table.remove(sorted_list)
    end

    -- 5. Ghi đè lại vào file log
    local f_write = io.open(log_file, "w")
    if f_write then
      for _, item in ipairs(sorted_list) do
        -- Sửa định dạng %d (số nguyên) thành %.1f (1 số thập phân)
        f_write:write(string.format("%.1f %s\n", item.score, item.path))
      end
      f_write:close()
    end
  end,
})
