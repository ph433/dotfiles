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

    -- 1. GHI LOG RECENCY
    local timestamp = os.time()
    local f_recency = io.open(recency_log_path, "a")
    if f_recency then
        f_recency:write(timestamp .. " " .. file_path .. "\n")
        f_recency:close()
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
