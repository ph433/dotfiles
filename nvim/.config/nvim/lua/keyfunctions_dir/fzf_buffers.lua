local M = {}

M.fzf_buffers = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  -- Provider: Thu thập các buffer đang hoạt động và format chuỗi hiển thị
  local function buffer_provider(fzf_cb)
    local cur_buf = vim.api.nvim_get_current_buf()
    local alt_buf = vim.fn.bufnr("#")

    local bufs = vim.tbl_filter(function(b)
      return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
    end, vim.api.nvim_list_bufs())

    -- Đưa buffer hiện tại hoặc alternate buffer lên trước để tiện switch
    table.sort(bufs, function(a, b)
      if a == cur_buf then return true end
      if b == cur_buf then return false end
      return a > b
    end)

    for _, bufnr in ipairs(bufs) do
      local name = vim.api.nvim_buf_get_name(bufnr)
      local disp_name = (name == "") and "[No Name]" or vim.fn.fnamemodify(name, ":~:.")
      
      -- Đánh dấu cờ giống :ls (active %, alternate #, modified +)
      local flag = " "
      if bufnr == cur_buf then
        flag = "%"
      elseif bufnr == alt_buf then
        flag = "#"
      end

      local mod = vim.bo[bufnr].modified and "+" or " "
      -- Format: [ID] flag mod | file_path
      local flags = (flag or " ") .. (mod or " ")
      local line = string.format("%-4s %-2s │ %s", string.format("[%d]", bufnr), flags, disp_name)
      fzf_cb(line)
    end

    fzf_cb(nil)
  end

  -- Cheatsheet preview
  local cheatsheet = [[
\27[1;34m=== FZF BUFFER PICKER CHEATSHEET ===\27[0m

\27[1;33m[ 1. NAVIGATION & ACTIONS ]\27[0m
  \27[32m<Enter>\27[0m     : Switch to selected buffer
  \27[33m<Tab>\27[0m       : Toggle cheatsheet / syntax preview
  \27[31m<Ctrl-x>\27[0m     : Delete buffer (bd) without closing picker
  \27[35m<Ctrl-z>\27[0m     : Clear query

\27[1;33m[ 2. CLIPBOARD (COPYQ) ]\27[0m
  \27[36m<Ctrl-c>\27[0m     : Copy file path to clipboard & CopyQ
  \27[34m<Ctrl-v>\27[0m     : Paste from Clipboard into search input

\27[1;33m[ 3. ICONS & FLAGS ]\27[0m
  \27[32m%\27[0m            : Current buffer
  \27[33m#\27[0m            : Alternate buffer
  \27[31m+\27[0m            : Modified buffer (unsaved)
]]

  local cache_dir = vim.fn.stdpath("cache")
  local cheat_file = cache_dir .. "/fzf_buf_cheat.txt"

  local f1 = io.open(cheat_file, "w")
  if f1 then 
    f1:write((cheatsheet:gsub("\\27", string.char(27))))
    f1:close() 
  end

  local cmd_cheatsheet = "cat '" .. cheat_file .. "'"

  -- Toggle Preview giữa nội dung file thực tế và bảng Cheatsheet
  local tab_bind = string.format("change-preview(%s)+toggle-preview", cmd_cheatsheet)

  -- Helper: Lấy bufnr từ chuỗi format "[ 1] %  │ filepath"
  local function parse_bufnr(selected_item)
    if not selected_item then return nil end
    local bufnr_str = selected_item:match("^%[(%s*%d+)%]")
    return bufnr_str and tonumber(vim.trim(bufnr_str)) or nil
  end

  local opts = {
    winopts = { height = 0.55, width = 0.8, border = "rounded" },
    prompt = "Buffers> ",
    header = ":: <Enter> open | <Ctrl-x> delete buffer | <Tab> help | <Ctrl-c> copy path",

    fzf_opts = {
      ["--preview"] = cmd_cheatsheet,
      ["--preview-window"] = "right:55%:hidden:wrap",
      ["--color"] = "hl:yellow:reverse:bold,hl+:yellow:reverse:bold,pointer:#ff79c6,marker:#ff79c6,bg+:#44475a,spinner:#ff79c6",
    },

    keymap = {
      fzf = {
        ["tab"]       = tab_bind,
        ["enter"]     = "accept",
        ["ctrl-up"]   = "half-page-up",
        ["ctrl-down"] = "half-page-down",
        ["ctrl-v"]    = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\r\n')\")",
        -- Trích xuất filepath từ cột 2 trở đi để add vào copyq
        ["ctrl-c"]    = [[execute-silent(echo -n {} | awk -F '│ ' '{print $2}' | tr -d '\n' | copyq add - && copyq select 0)]],
        ["ctrl-z"]    = "clear-query",
      },
    },

    actions = {
      ["default"] = function(selected, _)
        local item = selected and selected[1]
        local bufnr = parse_bufnr(item)
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
          vim.schedule(function()
            vim.api.nvim_set_current_buf(bufnr)
          end)
        end
      end,

      ["ctrl-x"] = {
        fn = function(selected, _)
          local item = selected and selected[1]
          local bufnr = parse_bufnr(item)
          if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end

          -- Đưa đường dẫn file vào clipboard trước khi đóng
          local name = vim.api.nvim_buf_get_name(bufnr)
          if name ~= "" then
            vim.fn.setreg("+", name)
            vim.fn.setreg('"', name)
            pcall(vim.fn.system, { "copyq", "add", "-" }, name)
            pcall(vim.fn.system, { "copyq", "select", "0" })
          end

          -- Đóng buffer bằng pcall để không làm crash UI nếu file chưa lưu
          local ok, err = pcall(vim.cmd, "bd " .. bufnr)
          if not ok then
            vim.notify("Không thể đóng buffer (chưa lưu?): " .. tostring(err), vim.log.levels.WARN)
          end
        end,
        noclose = true,
        reload = true,
      },
    },
  }

  fzf.fzf_exec(buffer_provider, opts)
end

return M
