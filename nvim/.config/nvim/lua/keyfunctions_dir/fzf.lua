local M = {}

M.fzf_command_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  -- Gộp 3 trang thành 1 cheatsheet duy nhất và phân chia rõ ràng
  local cheatsheet = [[
\033[1;34m=== FZF COMMAND HISTORY CHEATSHEET ===\033[0m

\033[1;33m[ 1. BASIC SHORTCUTS ]\033[0m
  \033[32m<Enter>\033[0m     : Execute selected item (or current query)
  \033[33m<Tab>\033[0m       : Run current query & save to history
  \033[35m<Ctrl-z>\033[0m    : Put selected item into input to edit

\033[1;33m[ 2. CLIPBOARD (COPYQ) ]\033[0m
  \033[36m<Ctrl-c>\033[0m    : Copy selected item to Clipboard
  \033[34m<Ctrl-v>\033[0m    : Paste from Clipboard to input

\033[1;33m[ 3. NAVIGATION ]\033[0m
  \033[31m<Ctrl-u/d>\033[0m  : Scroll list (half page up/down)
  \033[33m<?>\033[0m         : Toggle this Cheatsheet
  \033[36m<;>\033[0m         : Toggle Hello Preview
]]

  local cmd_cheatsheet = string.format("echo -e '%s'", cheatsheet:gsub("\n", "\\n"))
  local cmd_hello = "echo -e '\\033[1;32m=== XIN CHÀO ===\\033[0m\\n\\nChào bạn! Đây là preview mẫu.'"

  fzf.command_history({
    winopts = { height = 0.5, width = 0.8, border = "rounded" },
    prompt = "Cmd History> ",
    
    -- Text tiếng Anh thuần tủy, fzf-lua sẽ tự động bắt dấu < > để tô màu phím tắt
    header = ":: Press <?> Toggle Cheatsheet | <;> Toggle Hello",
    
    fzf_opts = {
      ["--preview"] = cmd_cheatsheet,
      ["--preview-window"] = "down:60%:hidden:wrap", -- Kéo dài xuống 60% để hiển thị đủ 1 trang
    },
    keymap = {
      fzf = {
        [":"]         = string.format("change-preview(%s)+toggle-preview", cmd_cheatsheet),
        [";"]         = string.format("change-preview(%s)+toggle-preview", cmd_hello),
        
        ["ctrl-z"]    = "transform-query(echo -n {})",
        ["ctrl-up"]   = "half-page-up",
        ["ctrl-down"] = "half-page-down",
        ["ctrl-v"]    = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\\r\\n')\")",
        ["ctrl-c"]    = "execute-silent(echo -n {} | copyq add - && copyq select 0)",
      },
    },
    actions = {
      ["tab"] = function(_, opts)
        local query = opts.last_query
        if query and #query > 0 then
          vim.fn.histadd("cmd", query)
          vim.cmd(query)
        end
      end,
      ["default"] = function(selected, opts)
        local cmd = (selected and selected[1]) or (opts and opts.last_query)
        if cmd and #cmd > 0 then
          vim.fn.histadd("cmd", cmd)
          vim.cmd(cmd)
        end
      end,
    },
  })
end

return M
