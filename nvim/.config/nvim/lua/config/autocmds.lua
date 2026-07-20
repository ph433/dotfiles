local function set_layout(layer)
    os.execute(string.format("echo '{\"ChangeLayer\": {\"new\": \"%s\"}}' | nc -w 1 localhost 1234 > /dev/null 2>&1 &", layer))
end

-- 1. Khi vừa vào Neovim HOẶC khi terminal chứa Neovim được focus trở lại
vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
    callback = function() set_layout("mod_nvim-active") end
})

-- 2. Khi thoát Neovim HOẶC khi bạn click/focus sang một terminal khác
vim.api.nvim_create_autocmd({ "VimLeave", "FocusLost" }, {
    callback = function() set_layout("mod_nvim") end -- Trả về layer mặc định của terminal
})

-- ==========================================================================
-- ĐỊNH DẠNG FILE & ĐIỀU HƯỚNG CẤU HÌNH KANATA (Đã xóa đoạn bị trùng lặp)
-- ==========================================================================
vim.filetype.add({
  extension = {
    kbd       = "kanata",
    gitconfig = "gitconfig",
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "kanata",
  callback = function()
    vim.bo.commentstring = ";; %s"
  end,
})

-- ==========================================================================
-- XỬ LÝ FRECENCY LOG & CHỐNG TRÙNG LẶP CHO STARSHIP
-- ==========================================================================
-- Đường dẫn file log recency
local recency_log_path = vim.fn.expand('~/.cache/nvim_recent.log')
local track_files_group = vim.api.nvim_create_augroup("TrackRecentFiles", { clear = true })

-- Tách logic xử lý cốt lõi ra một hàm riêng
local function log_and_score_buffer(buf)
    local file_path = vim.api.nvim_buf_get_name(buf)
    
    -- Lọc bỏ các buffer rỗng, file rác, terminal, NvimTree...
    if file_path == "" 
       or file_path:match("toggleterm") 
       or file_path:match("NvimTree") 
       or vim.bo[buf].buftype ~= "" then
        return
    end

    -- Giải mã Symlink (Stow) về đường dẫn vật lý gốc
    local real_path = vim.loop.fs_realpath(file_path)
    if real_path then
        file_path = real_path
    end

    -- 1. GHI LOG RECENCY (Đã sửa lỗi trùng lặp)
    local timestamp = os.time()
    local lines = {}
    
    -- Đọc file log hiện tại và lọc bỏ dòng chứa đường dẫn file này
    local f_read = io.open(recency_log_path, "r")
    if f_read then
        for line in f_read:lines() do
            -- Dùng string.find với tham số plain=true thay vì line:match
            if not string.find(line, file_path, 1, true) then
                table.insert(lines, line)
            end
        end
        f_read:close()
    end
    
    -- Giới hạn tối đa 500 file gần nhất để tối ưu tốc độ đọc của Starship
    while #lines > 500 do
        table.remove(lines, #lines)
    end

    -- Ghi đè file với thông tin mới nhất lên đầu (Dùng "w" thay vì "a")
    local f_write = io.open(recency_log_path, "w")
    if f_write then
        f_write:write(timestamp .. " " .. file_path .. "\n")
        for _, line in ipairs(lines) do
            f_write:write(line .. "\n")
        end
        f_write:close()
    end

    -- 2. TÍNH ĐIỂM FRECENCY ĐỒNG BỘ
    local safe_path = vim.fn.shellescape(file_path)
    local cmd = {'fish', '-c', '__fzf_score_file ' .. safe_path}
    vim.fn.jobstart(cmd, { detach = true })
end

-- AUTOCMD 1: KHI MỞ FILE (Vẫn giữ cơ chế chặn spam)
vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
    group = track_files_group,
    callback = function(args)
        if vim.w.frecency_logged then
            return
        end
        vim.w.frecency_logged = true
        log_and_score_buffer(args.buf)
    end,
})

-- AUTOCMD 2: KHI THOÁT NVIM (Tính thêm 1 lần cho file đang mở cuối cùng)
vim.api.nvim_create_autocmd("VimLeavePre", {
    group = track_files_group,
    callback = function()
        -- Lấy buffer của cửa sổ đang active ngay trước khi quit
        local current_buf = vim.api.nvim_get_current_buf()
        log_and_score_buffer(current_buf)
    end,
})

-- -- Tự động chạy script cập nhật Dwm Bar mỗi khi mở một file mới hoặc lưu file (BufEnter, BufWritePost)
-- vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
--     group = vim.api.nvim_create_augroup("DwmBarUpdate", { clear = true }),
--     callback = function()
--         -- Kiểm tra nếu là file thật sự tồn tại trên ổ cứng (tránh các cửa sổ ẩn như NvimTree, Telescope)
--         if vim.bo.buftype == "" and vim.fn.filereadable(vim.fn.expand("%:p")) == 1 then
--             -- Chạy ngầm script sh bằng hàm uv (hoặc loop) của Neovim để không gây lag khi code
--             local vim_fn = vim.uv or vim.loop
--             vim_fn.spawn("/home/phuong/dwm-flexipatch/dwm_status_update.sh", {
--                 args = {},
--                 detached = true
--             }, function() end)
--         end
--     end,
-- })
