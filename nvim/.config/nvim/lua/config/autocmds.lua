-- ==========================================================================
-- 2. ĐỊNH DẠNG FILE & ĐIỀU HƯỚNG CẤU HÌNH KANATA
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

-- Đường dẫn các file log
local recency_log_path = vim.fn.expand('~/.cache/nvim_recent.log')
local frecency_dir = vim.fn.expand("~/.cache/yazi/")
vim.fn.mkdir(frecency_dir, "p")
local frecency_log_path = frecency_dir .. "file_recent.log"

-- Tạo 1 Group chung duy nhất
local track_files_group = vim.api.nvim_create_augroup("TrackRecentFiles", { clear = true })

vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
    group = track_files_group,
    callback = function(args)
        -- 1. BỘ LỌC CHUNG
        -- Cơ chế chặn spam focus
        if vim.w.frecency_logged then
            return
        end

        local file_path = vim.api.nvim_buf_get_name(args.buf)
        
        -- Lọc bỏ các buffer rỗng, file rác, terminal, NvimTree...
        if file_path == "" 
           or file_path:match("toggleterm") 
           or file_path:match("NvimTree") 
           or vim.bo[args.buf].buftype ~= "" then
            return
        end

        -- Giải mã Symlink (Stow) về đường dẫn vật lý gốc
        local real_path = vim.loop.fs_realpath(file_path)
        if real_path then
            file_path = real_path
        end

        -- Đánh dấu cửa sổ hiện tại đã xử lý xong
        vim.w.frecency_logged = true


        -- 2. TÁC VỤ 1: GHI LOG RECENCY (Thời gian thực cho fzf)
        local timestamp = os.time()
        local f_recency = io.open(recency_log_path, "a")
        if f_recency then
            f_recency:write(timestamp .. " " .. file_path .. "\n")
            f_recency:close()
        end


        -- 3. TÁC VỤ 2: TÍNH ĐIỂM FRECENCY (Tần suất cho Yazi/fzf)
        local files_score = {}
        local f_read = io.open(frecency_log_path, "r")
        
        -- Đọc và nạp dữ liệu cũ
        if f_read then
            for line in f_read:lines() do
                local score, path = line:match("^(%S+)%s+(.+)$")
                if score and path then
                    score = score:gsub(",", ".")
                    files_score[path] = tonumber(score)
                end
            end
            f_read:close()
        end

        -- Cập nhật điểm cho file hiện tại
        if files_score[file_path] then
            files_score[file_path] = files_score[file_path] + 10 
        else
            files_score[file_path] = 10 
        end

        -- Giảm điểm các file khác
        for path, score in pairs(files_score) do
            if path ~= file_path then
                files_score[path] = math.max(1.0, score - 1)
            end
        end

        -- Sắp xếp theo điểm từ cao xuống thấp
        local sorted_list = {}
        for path, score in pairs(files_score) do
            table.insert(sorted_list, { path = path, score = score })
        end
        table.sort(sorted_list, function(a, b) return a.score > b.score end)

        -- Giới hạn lưu tối đa 100 file
        while #sorted_list > 100 do
            table.remove(sorted_list)
        end

        -- Ghi đè lại vào file log
        local f_write = io.open(frecency_log_path, "w")
        if f_write then
            for _, item in ipairs(sorted_list) do
                f_write:write(string.format("%.1f %s\n", item.score, item.path))
            end
            f_write:close()
        end
    end,
})
