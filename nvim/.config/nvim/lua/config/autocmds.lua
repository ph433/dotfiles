local timer = nil

local function set_layout(layer)
    local cmd = string.format("echo '{\"ChangeLayer\": {\"new\": \"%s\"}}' | nc -w 1 localhost 1234", layer)
    vim.fn.jobstart({ "sh", "-c", cmd }, { detach = true })
end

-- Xác định chính xác layer cần dùng dựa theo buffer hiện tại
local function get_active_layer()
    if vim.bo.filetype == "netrw" then
        return "mod_firefox"
    end
    return "mod_nvim"
end

local group = vim.api.nvim_create_augroup("KanataLayerControl", { clear = true })

-- 1. Khi VÀO Neovim HOẶC nhận lại Focus (khi đổi tag workspace quay lại)
vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
    group = group,
    callback = function()
        if timer then
            timer:stop()
            timer:close()
            timer = nil
        end

        timer = vim.loop.new_timer()
        timer:start(40, 0, vim.schedule_wrap(function()
            -- Lấy đúng layer theo buffer đang hiển thị thay vì ép cứng mod_nvim
            set_layout(get_active_layer())
            if timer then
                timer:close()
                timer = nil
            end
        end))
    end
})

-- 2. Khi THOÁT Neovim HOẶC mất Focus
vim.api.nvim_create_autocmd({ "VimLeave", "FocusLost" }, {
    group = group,
    callback = function()
        if timer then
            timer:stop()
            timer:close()
            timer = nil
        end
        set_layout("base")
    end
})

-- 3. Khi VÀO command-line (bấm :, /, ?, hoặc prompt d / % của Netrw)
vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = group,
    callback = function()
        if timer then
            timer:stop()
            timer:close()
            timer = nil
        end
        set_layout("mod_firefox")
    end
})

-- 4. Khi THOÁT command-line (nhấn Enter sau khi nhập tên file/dir ở d, %)
vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function()
        -- Kiểm tra lại: nếu vẫn đang đứng ở Netrw thì giữ nguyên mod_firefox
        set_layout(get_active_layer())
    end
})

-- 5. Xử lý khi mở Netrw
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = group,
    callback = function()
        if vim.bo.filetype == "netrw" then
            set_layout("mod_firefox")
        end
    end
})

-- 6. Khi rời buffer Netrw sang file code bình thường
vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    callback = function()
        if vim.bo.filetype == "netrw" then
            set_layout("mod_nvim")
        end
    end
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

local augroup = vim.api.nvim_create_augroup("LogRecentFiles", { clear = true })

-- Hàm hỗ trợ thực thi lệnh Fish async
local function run_fish_cmd(cmd)
  -- vim.system({ "fish", "-c", cmd })
  vim.fn.jobstart({ "fish", "-c", cmd }, { detach = true })
end

-- 1. KHI MỞ FILE (BufReadPost): Ghi log file, tính Score file, VÀ ghi log thư mục
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  pattern = "*",
  callback = function(args)
    local filepath = vim.api.nvim_buf_get_name(args.buf)
    if filepath ~= "" and vim.bo[args.buf].buftype == "" then
      local dirpath = vim.fs.dirname(filepath)
      
      local safe_file = vim.fn.shellescape(filepath)
      local safe_dir = vim.fn.shellescape(dirpath)

      -- Chạy đồng thời log file, score file và log thư mục
      run_fish_cmd(string.format(
        "log_recent_file %s; __fzf_score_file %s; log_recent_dir %s",
        safe_file, safe_file, safe_dir
      ))
    end
  end,
})

-- 2. KHI ĐÓNG FILE (BufUnload): Ghi log file VÀ ghi log thư mục
vim.api.nvim_create_autocmd("BufUnload", {
  group = augroup,
  pattern = "*",
  callback = function(args)
    local filepath = vim.api.nvim_buf_get_name(args.buf)
    if filepath ~= "" and vim.bo[args.buf].buftype == "" then
      local dirpath = vim.fs.dirname(filepath)

      local safe_file = vim.fn.shellescape(filepath)
      local safe_dir = vim.fn.shellescape(dirpath)

      -- Chạy log file và log thư mục khi đóng buffer
      run_fish_cmd(string.format(
        "log_recent_file %s; log_recent_dir %s",
        safe_file, safe_dir
      ))
    end
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
