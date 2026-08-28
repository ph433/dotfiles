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
    
    local new_lines = {}
    for _, line in ipairs(lines) do
      if vim.trim(line) ~= cmd_str then
        table.insert(new_lines, line)
      end
    end
    
    table.insert(new_lines, cmd_str)
    vim.fn.writefile(new_lines, history_file)
  end

  local cheatsheet = [[
\27[1;34m=== FZF COMMAND HISTORY CHEATSHEET ===\27[0m

\27[1;33m[ 1. BASIC SHORTCUTS ]\27[0m
  \27[32m<Enter>\27[0m     : Execute selected item
  \27[33m<Tab>\27[0m       : [Empty] Toggle Help | [Text] Run EXACT query
  \27[35m<Ctrl-z>\27[0m    : Clear query
  \27[31m<Ctrl-x>\27[0m    : Delete selected item from history

\27[1;33m[ 2. CLIPBOARD (COPYQ) ]\27[0m
  \27[36m<Ctrl-c>\27[0m    : Copy selected item to clipboard
  \27[34m<Ctrl-v>\27[0m    : Paste from Clipboard to input

\27[1;33m[ 3. NAVIGATION ]\27[0m
  \27[33m<?>\27[0m         : Toggle this Cheatsheet
  \27[36m<;>\27[0m         : Toggle Hello Preview
]]

  local hello_txt = "\\27[1;32m=== HELLO ===\\27[0m\n\nHello! This is a sample preview."

  local cache_dir = vim.fn.stdpath("cache")
  local cheat_file = cache_dir .. "/fzf_cheat.txt"
  local hello_file = cache_dir .. "/fzf_hello.txt"

  local f1 = io.open(cheat_file, "w")
  if f1 then f1:write((cheatsheet:gsub("\\27", string.char(27)))); f1:close() end

  local f2 = io.open(hello_file, "w")
  if f2 then f2:write((hello_txt:gsub("\\27", string.char(27)))); f2:close() end

  local cmd_cheatsheet = "cat '" .. cheat_file .. "'"
  local cmd_hello = "cat '" .. hello_file .. "'"

  -- GÁN PHÍM ẢO: Dùng alt-enter để fzf-lua không chặn phím Tab
  local tab_bind = string.format(
    [[transform:if [ -z "$FZF_QUERY" ]; then echo "change-preview(%s)+toggle-preview"; else echo 'become(echo alt-enter; printf "%%s\n" "$FZF_QUERY")'; fi]],
    cmd_cheatsheet
  )

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
        
        -- Mapping Tab chỉ được đăng ký ở đây, KHÔNG xuất hiện trong bảng actions
        ["tab"]       = tab_bind,
        
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
          append_to_file(trimmed)
          vim.schedule(function()
            vim.fn.histadd("cmd", trimmed)
            local keys = vim.api.nvim_replace_termcodes(":" .. trimmed .. "<CR>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", true)
          end)
        end
      end,

      -- FIX: Bắt tín hiệu "alt-enter" được bắn ra từ become() khi Tab có chứa chữ
      ["alt-enter"] = function(selected, _)
        local query = (selected and selected[1]) or ""
        local trimmed = vim.trim(query)

        if #trimmed > 0 then
          append_to_file(trimmed)
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

          -- Xóa dòng trong file
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

          -- Dọn rác tạm trong RAM
          local total_history = vim.fn.histnr("cmd")
          for i = total_history, 1, -1 do
            if vim.trim(vim.fn.histget("cmd", i)) == trimmed then
              vim.fn.histdel("cmd", i)
            end
          end
        end,
        noclose = true,
        reload = true, 
      },
    },
  }

  fzf.fzf_exec(history_provider, opts)
end

return M
