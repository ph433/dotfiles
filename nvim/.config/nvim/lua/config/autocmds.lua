local timer = nil

local function set_layout(layer)
    local cmd = string.format("echo '{\"ChangeLayer\": {\"new\": \"%s\"}}' | nc -w 1 localhost 1234", layer)
    vim.fn.jobstart({"sh", "-c", cmd}, { detach = true })
end

-- 1. Khi VÀO Neovim HOẶC nhận lại Focus
vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
    callback = function()
        -- Nếu đang có timer chờ từ trước -> Hủy bỏ ngay
        if timer then
            timer:stop()
            timer:close()
            timer = nil
        end

        -- Tạo timer mới với uv (libuv) để có thể hủy bất cứ lúc nào
        timer = vim.loop.new_timer()
        timer:start(40, 0, vim.schedule_wrap(function()
            set_layout("mod_nvim-active")
            if timer then
                timer:close()
                timer = nil
            end
        end))
    end
})

-- 2. Khi THOÁT Neovim HOẶC mất Focus
vim.api.nvim_create_autocmd({ "VimLeave", "FocusLost" }, {
    callback = function()
        -- CRITICAL: Hủy ngay lệnh đổi active đang chờ (nếu có)
        if timer then
            timer:stop()
            timer:close()
            timer = nil
        end

        set_layout("mod_nvim")
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
