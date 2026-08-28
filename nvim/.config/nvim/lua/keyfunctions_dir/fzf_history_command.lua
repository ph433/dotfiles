local M = {}

M.fzf_command_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  -- File nguồn để đồng bộ giữa các cửa sổ dwm
  local history_file = vim.fn.expand("~/.config/nvim/custom_cmd_history.txt")

  -- Hàm đọc trực tiếp từ file thay vì lấy từ RAM Neovim
  local function history_provider(fzf_cb)
    if vim.fn.filereadable(history_file) == 1 then
      local lines = vim.fn.readfile(history_file)
      -- Đọc ngược từ dưới lên để lệnh mới nhất nằm trên cùng
      for i = #lines, 1, -1 do
        local cmd = vim.trim(lines[i])
        if cmd ~= "" then
          fzf_cb(cmd)
        end
      end
    end
    fzf_cb(nil)
  end

  -- Hàm hỗ trợ: Ghi thêm 1 dòng vào cuối file và loại bỏ trùng lặp
  local function append_to_file(cmd_str)
    local lines = {}
    if vim.fn.filereadable(history_file) == 1 then
      lines = vim.fn.readfile(history_file)
    end
    
    -- Xóa các dòng cũ bị trùng với lệnh mới (để đẩy lệnh này lên đầu)
    local new_lines = {}
    for _, line in ipairs(lines) do
      if vim.trim(line) ~= cmd_str then
        table.insert(new_lines, line)
      end
    end
    
    table.insert(new_lines, cmd_str)
    vim.fn.writefile(new_lines, history_file)
  end

  -- [GIỮ NGUYÊN PHẦN CHEATSHEET & TẠO FILE HELLO/CHEAT]
  local cheatsheet = [[...]] -- (Giữ nguyên text của bạn)
  local hello_txt = "..."    -- (Giữ nguyên)
  -- ... (Phần tạo file /tmp/fzf_cheat.txt giữ nguyên)
  local cmd_cheatsheet = "cat " .. vim.fn.stdpath("cache") .. "/fzf_cheat.txt"
  local cmd_hello = "cat " .. vim.fn.stdpath("cache") .. "/fzf_hello.txt"

  local opts = {
    winopts = { height = 0.55, width = 0.8, border = "rounded" },
    prompt = "Cmd History> ",
    header = ":: <Enter> run selected | <Tab> run query | <?> help | <Ctrl-x> delete",
    
    fzf_opts = {
      ["--preview"] = cmd_cheatsheet,
      ["--preview-window"] = "down:60%:hidden:wrap",
      ["--color"] = "hl:yellow:reverse:bold,hl+:yellow:reverse:bold,pointer:#ff79c6,marker:#ff79c6,bg+:#44475a,spinner:#ff79c6",
    },
    
    keymap = {
      fzf = {
        ["?"]         = string.format("change-preview(%s)+toggle-preview", cmd_cheatsheet),
        [":"]         = string.format("change-preview(%s)+toggle-preview", cmd_cheatsheet),
        [";"]         = string.format("change-preview(%s)+toggle-preview", cmd_hello),
        ["enter"]     = "accept",
        ["ctrl-y"]    = "transform-query(echo -n {})",
        ["ctrl-up"]   = "half-page-up",
        ["ctrl-down"] = "half-page-down",
        ["ctrl-v"]    = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\r\n')\")",
        ["ctrl-c"]    = "execute-silent(echo -n {} | copyq add - && copyq select 0)",
        ["ctrl-z"]    = "clear-query",
      },
    },
    
    actions = {
      ["default"] = function(selected, act_opts)
        local query = (act_opts and (act_opts.last_query or act_opts.query)) or ""
        local selected_item = (selected and selected[1]) or ""
        local cmd = (selected_item ~= "") and selected_item or query
        local trimmed = vim.trim(cmd)

        if #trimmed > 0 then
          append_to_file(trimmed) -- Ghi vào file chung
          vim.schedule(function()
            vim.fn.histadd("cmd", trimmed) -- Cập nhật nhẹ vào RAM Neovim hiện tại
            local keys = vim.api.nvim_replace_termcodes(":" .. trimmed .. "<CR>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", true)
          end)
        end
      end,

      ["tab"] = function(_, act_opts)
        local query = (act_opts and (act_opts.last_query or act_opts.query)) or ""
        local trimmed = vim.trim(query)

        if #trimmed > 0 then
          append_to_file(trimmed) -- Ghi vào file chung
          vim.schedule(function()
            vim.fn.histadd("cmd", trimmed)
            local keys = vim.api.nvim_replace_termcodes(":" .. trimmed .. "<CR>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", true)
          end)
        end
      end,
      
      ["ctrl-x"] = {
        fn = function(selected, _)
          local item = (selected and selected[1]) or ""
          local trimmed = vim.trim(item)
          if #trimmed == 0 then return end

          -- Đẩy vào Clipboard & CopyQ
          vim.fn.setreg("+", trimmed)
          vim.fn.setreg('"', trimmed)
          vim.fn.system({ "copyq", "add", "-" }, trimmed)
          vim.fn.system({ "copyq", "select", "0" })

          -- CHỈ CẦN XÓA DÒNG TRONG FILE
          if vim.fn.filereadable(history_file) == 1 then
            local lines = vim.fn.readfile(history_file)
            local new_lines = {}
            for _, line in ipairs(lines) do
              if vim.trim(line) ~= trimmed then
                table.insert(new_lines, line)
              end
            end
            vim.fn.writefile(new_lines, history_file)
          end

          -- Dọn rác tạm trong RAM của Neovim hiện tại (để nó không hiện lại nếu dùng phím mũi tên)
          local total_history = vim.fn.histnr("cmd")
          for i = total_history, 1, -1 do
            if vim.trim(vim.fn.histget("cmd", i)) == trimmed then
              vim.fn.histdel("cmd", i)
            end
          end
        end,
        noclose = true,
        reload = true, -- Sẽ gọi lại history_provider để load lại từ file ngay lập tức
      },
    },
  }

  fzf.fzf_exec(history_provider, opts)
end

return M
