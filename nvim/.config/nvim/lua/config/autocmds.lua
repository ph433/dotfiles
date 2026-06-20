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

-- Đường dẫn file log recency
local recency_log_path = vim.fn.expand('~/.cache/nvim_recent.log')

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


        -- 3. TÁC VỤ 2: TÍNH ĐIỂM FRECENCY ĐỒNG BỘ
        -- Bắn tín hiệu sang Fish để gọi hàm trung tâm xử lý, chạy ngầm (detach)
        local safe_path = vim.fn.shellescape(file_path)
        local cmd = {'fish', '-c', '__fzf_score_file ' .. safe_path}
        
        vim.fn.jobstart(cmd, { detach = true })
    end,
})
