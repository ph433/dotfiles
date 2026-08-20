local M = {}

M.fzf_command_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  local cheatsheet = [[
\27[1;34m=== FZF COMMAND HISTORY CHEATSHEET ===\27[0m

\27[1;33m[ 1. BASIC SHORTCUTS ]\27[0m
  \27[32m<Enter>\27[0m     : Execute selected item (fuzzy match)
  \27[33m<Tab>\27[0m       : [Empty] Toggle Help | [Text] Run EXACT query
  \27[35m<Ctrl-z>\27[0m    : Put selected item into input to edit
  \27[31m<Ctrl-a>\27[0m    : Clear entire query input

\27[1;33m[ 2. CLIPBOARD (COPYQ) ]\27[0m
  \27[36m<Ctrl-c>\27[0m    : Copy selected item to Clipboard
  \27[34m<Ctrl-v>\27[0m    : Paste from Clipboard to input

\27[1;33m[ 3. NAVIGATION ]\27[0m
  \27[31m<Ctrl-u/d>\27[0m  : Scroll list (half page up/down)
  \27[33m<?>\27[0m         : Toggle this Cheatsheet
  \27[36m<;>\27[0m         : Toggle Hello Preview
]]

  local hello_txt = "\\27[1;32m=== HELLO ===\\27[0m\n\nHello! This is a sample preview."

  -- Ghi file tạm để shell đọc mượt mà không dính lỗi cú pháp nháy kép
  local cache_dir = vim.fn.stdpath("cache")
  local cheat_file = cache_dir .. "/fzf_cheat.txt"
  local hello_file = cache_dir .. "/fzf_hello.txt"

  local f1 = io.open(cheat_file, "w")
  if f1 then f1:write((cheatsheet:gsub("\\27", string.char(27)))); f1:close() end

  local f2 = io.open(hello_file, "w")
  if f2 then f2:write((hello_txt:gsub("\\27", string.char(27)))); f2:close() end

  local cmd_cheatsheet = "cat " .. cheat_file
  local cmd_hello = "cat " .. hello_file

  fzf.command_history({
    winopts = { height = 0.55, width = 0.8, border = "rounded" },
    prompt = "Cmd History> ",
    header = ":: <Tab> exact/help | <Ctrl-z> edit | <Ctrl-a> clear | <Ctrl-c> copy",
    
    fzf_opts = {
      ["--preview"] = cmd_cheatsheet,
      ["--preview-window"] = "down:60%:hidden:wrap",
    },
    
    keymap = {
      fzf = {
        ["?"]         = string.format("change-preview(%s)+toggle-preview", cmd_cheatsheet),
        [":"]         = string.format("change-preview(%s)+toggle-preview", cmd_cheatsheet),
        [";"]         = string.format("change-preview(%s)+toggle-preview", cmd_hello),
        
        -- XỬ LÝ LÕI TẠI ĐÂY:
        -- Nếu rỗng (-z): Bật cheatsheet (không đóng GUI).
        -- Nếu có chữ: Dùng "become" ép FZF in ra 1 dòng trống (làm giả tín hiệu accept) và dòng 2 là biến $FZF_QUERY.
        -- fzf-lua sẽ tưởng đó chính là kết quả selected[1].
        ["tab"]       = string.format([[transform:sh -c 'if [ -z "$FZF_QUERY" ]; then echo "change-preview(%s)+toggle-preview"; else echo "become(echo; echo \"$FZF_QUERY\")"; fi']], cmd_cheatsheet),
        
        ["ctrl-a"]    = "clear-query",
        ["ctrl-z"]    = "transform-query(echo -n {})",
        ["ctrl-up"]   = "half-page-up",
        ["ctrl-down"] = "half-page-down",
        ["ctrl-v"]    = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\\r\\n')\")",
        ["ctrl-c"]    = "execute-silent(echo -n {} | copyq add - && copyq select 0)",
      },
    },
    
    actions = {
      -- Lúc này hàm default trở nên cực kỳ đơn giản và sạch sẽ, không cần check loằng ngoằng nữa
      ["default"] = function(selected, _)
        -- Nhờ Trick "become" bên trên:
        -- Khi bấm Enter -> selected[1] là dòng bôi sáng.
        -- Khi bấm Tab   -> selected[1] sẽ là chính xác nội dung ô Query.
        local cmd = selected and selected[1] or ""
        local trimmed = vim.trim(cmd)

        if #trimmed > 0 then
          vim.schedule(function()
            vim.fn.histadd("cmd", trimmed)
            local keys = vim.api.nvim_replace_termcodes(":" .. trimmed .. "<CR>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", true)
          end)
        end
      end,
    },
  })
end

return M
