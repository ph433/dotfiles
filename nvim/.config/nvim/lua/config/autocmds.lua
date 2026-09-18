local timer = nil

local function set_layout(layer)
    local cmd = string.format("echo '{\"ChangeLayer\": {\"new\": \"%s\"}}' | nc -w 1 localhost 1234", layer)
    vim.fn.jobstart({ "sh", "-c", cmd }, { detach = true })
end

-- Xác định chính xác layer cần dùng dựa theo buffer hiện tại
local function get_active_layer()
    if vim.bo.buftype == "terminal" then
        return "base" -- hoặc layer bạn muốn dùng khi gõ trong terminal (vd: base/mod_terminal)
    end
    if vim.bo.filetype == "netrw" then
        return "mod_nvim_netrw"
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

-- Danh sách bỏ qua để fzf-lua tự quản lý window/prompt
local ignored_term_fts = {
    ["fzf"] = true,
    ["fzf-lua"] = true,
}

-- Khi MỞ terminal hoặc CHUYỂN VÀO terminal
vim.api.nvim_create_autocmd({ "TermOpen", "TermEnter", "BufEnter" }, {
    group = group,
    callback = function(args)
        if vim.bo.buftype == "terminal" then
            local ft = vim.bo[args.buf].filetype
            
            -- Đổi layout Kanata
            set_layout(get_active_layer())

            -- Tự vào Insert mode và tắt số dòng (chỉ cho terminal thường)
            if not ignored_term_fts[ft] then
                vim.opt_local.number = false
                vim.opt_local.relativenumber = false
                vim.cmd("startinsert")
            end
        end
    end,
})

-- Khi THOÁT terminal mode (bấm <C-\><C-n> hoặc sang buffer khác)
vim.api.nvim_create_autocmd({ "TermLeave", "BufLeave" }, {
    group = group,
    callback = function()
        if vim.bo.buftype == "terminal" then
            -- Khi rời terminal trở lại buffer code bình thường
            vim.schedule(function()
                set_layout(get_active_layer())
            end)
        end
    end,
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

local home = vim.env.HOME
local file_log = home .. "/.cache/nvim_recent.log"
local dir_log = home .. "/.cache/dir_recent.log"

-- 1. Helper: Ghi log file + log dir + tính điểm (khi MỞ FILE)
local function log_open_file(filepath, dirpath)
  vim.system({
    "sh", "-c",
    'log_add.sh "$1" "$2"; log_add.sh "$3" "$4"; fzf_score_file.sh "$2"',
    "_",
    file_log, filepath,
    dir_log, dirpath
  }, { detach = true })
end

-- 2. Helper: Ghi log file + log dir (khi ĐÓNG FILE)
local function log_unload_file(filepath, dirpath)
  vim.system({
    "sh", "-c",
    'log_add.sh "$1" "$2"; log_add.sh "$3" "$4"',
    "_",
    file_log, filepath,
    dir_log, dirpath
  }, { detach = true })
end

-- 3. Helper: Chỉ ghi log dir (dùng cho Netrw)
local function log_dir_only(dirpath)
  vim.system({
    "sh", "-c",
    'log_add.sh "$1" "$2"',
    "_",
    dir_log, dirpath
  }, { detach = true })
end

local last_dir = ""
local opened_file_just_now = false

-- 1. KHI MỞ FILE THƯỜNG
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  pattern = "*",
  callback = function(args)
    local filepath = vim.api.nvim_buf_get_name(args.buf)
    if filepath == "" or vim.bo[args.buf].buftype ~= "" then
      return
    end

    local stat = vim.uv.fs_stat(filepath)
    if stat and stat.type == "file" then
      opened_file_just_now = true
      last_dir = ""
      local dirpath = vim.fs.dirname(filepath)
      log_open_file(filepath, dirpath)
    end
  end,
})

-- 2. DUYỆT THƯ MỤC NETRW (Mở hoặc nhảy vào thư mục con)
local function check_and_log_netrw(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf then
    return
  end

  local dir = vim.b[buf].netrw_curdir or vim.api.nvim_buf_get_name(buf)
  if not dir or dir == "" then return end
  dir = dir:gsub("/+$", "")

  local stat = vim.uv.fs_stat(dir)
  if stat and stat.type == "directory" then
    if last_dir ~= dir then
      last_dir = dir
      log_dir_only(dir)
    end
  end
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = augroup,
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].filetype == "netrw" then
      opened_file_just_now = false
      vim.schedule(function()
        check_and_log_netrw(args.buf)
      end)
    end
  end,
})

-- 3. KHI ĐÓNG BUFFER (UNLOAD)
vim.api.nvim_create_autocmd("BufUnload", {
  group = augroup,
  pattern = "*",
  callback = function(args)
    local is_netrw = (vim.bo[args.buf].filetype == "netrw")
    local filepath = vim.api.nvim_buf_get_name(args.buf)

    -- Trường hợp A: Đóng thư mục Netrw
    if is_netrw then
      local dir = vim.b[args.buf].netrw_curdir or filepath
      if dir == "" then return end
      dir = dir:gsub("/+$", "")

      local stat = vim.uv.fs_stat(dir)
      if stat and stat.type == "directory" then
        last_dir = ""
        vim.schedule(function()
          -- Chỉ ghi log thoát dir nếu người dùng thoát Netrw mà KHÔNG mở file
          if not opened_file_just_now then
            log_dir_only(dir)
          end
          opened_file_just_now = false
        end)
      end
      return
    end

    -- Trường hợp B: Đóng file thông thường
    if filepath == "" or vim.bo[args.buf].buftype ~= "" then
      return
    end

    local stat = vim.uv.fs_stat(filepath)
    if stat and stat.type == "file" then
      log_unload_file(filepath, vim.fs.dirname(filepath))
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
