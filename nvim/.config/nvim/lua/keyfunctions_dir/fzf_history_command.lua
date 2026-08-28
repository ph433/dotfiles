local M = {}

M.fzf_command_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  local function history_provider(fzf_cb)
    local total_history = vim.fn.histnr("cmd")
    for i = total_history, 1, -1 do
      local cmd = vim.fn.histget("cmd", i)
      if cmd ~= "" then
        fzf_cb(cmd)
      end
    end
    fzf_cb(nil)
  end

  local cheatsheet = [[
\27[1;34m=== FZF COMMAND HISTORY CHEATSHEET ===\27[0m

\27[1;33m[ 1. BASIC SHORTCUTS ]\27[0m
  \27[32m<Enter>\27[0m     : Execute selected item
  \27[33m<Tab>\27[0m       : Run EXACT query from search box
  \27[35m<Ctrl-z>\27[0m    : Clear query
  \27[31m<Ctrl-x>\27[0m    : Delete selected item from history

\27[1;33m[ 2. CLIPBOARD (COPYQ) ]\27[0m
  \27[36m<Ctrl-c>\27[0m    : Copy selected item to clipboard
  \27[34m<Ctrl-v>\27[0m    : Paste from Clipboard to input

\27[1;33m[ 3. NAVIGATION ]\27[0m
  \27[33m<?>\27[0m          : Toggle this Cheatsheet
  \27[36m<;>\27[0m          : Toggle Hello Preview
]]

  local hello_txt = "\\27[1;32m=== HELLO ===\\27[0m\n\nHello! This is a sample preview."

  local cache_dir = vim.fn.stdpath("cache")
  local cheat_file = cache_dir .. "/fzf_cheat.txt"
  local hello_file = cache_dir .. "/fzf_hello.txt"

  local f1 = io.open(cheat_file, "w")
  if f1 then f1:write((cheatsheet:gsub("\\27", string.char(27)))); f1:close() end

  local f2 = io.open(hello_file, "w")
  if f2 then f2:write((hello_txt:gsub("\\27", string.char(27)))); f2:close() end

  local cmd_cheatsheet = "cat " .. cheat_file
  local cmd_hello = "cat " .. hello_file

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
        ["ctrl-v"]    = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\\r\\n')\")",
        ["ctrl-c"]    = "execute-silent(echo -n {} | copyq add - && copyq select 0)",
        ["ctrl-z"]    = "clear-query",
      },
    },
    
    actions = {
      -- Enter: Ưu tiên dòng đang chọn trên danh sách
      ["default"] = function(selected, act_opts)
        local query = (act_opts and (act_opts.last_query or act_opts.query)) or ""
        local selected_item = (selected and selected[1]) or ""
        local cmd = (selected_item ~= "") and selected_item or query

        local trimmed = vim.trim(cmd)
        if #trimmed > 0 then
          vim.schedule(function()
            vim.fn.histadd("cmd", trimmed)
            local keys = vim.api.nvim_replace_termcodes(":" .. trimmed .. "<CR>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", true)
          end)
        end
      end,

      -- Tab: Ép chạy chính xác chuỗi đang nhập trong query (không bị mất ngoặc "")
      ["tab"] = function(_, act_opts)
        local query = (act_opts and (act_opts.last_query or act_opts.query)) or ""
        local trimmed = vim.trim(query)
        if #trimmed > 0 then
          vim.schedule(function()
            vim.fn.histadd("cmd", trimmed)
            local keys = vim.api.nvim_replace_termcodes(":" .. trimmed .. "<CR>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", true)
          end)
        end
      end,

      -- Ctrl-x: Xóa mục được chọn và sync ShaDa
      ["ctrl-x"] = {
        fn = function(selected, _)
          local item = (selected and selected[1]) or ""
          local trimmed = vim.trim(item)
          if #trimmed > 0 then
            vim.fn.setreg("+", trimmed)
            vim.fn.setreg('"', trimmed)
            vim.fn.system({ "copyq", "add", "-" }, trimmed)
            vim.fn.system({ "copyq", "select", "0" })

            pcall(vim.cmd, "rshada!")

            local total_history = vim.fn.histnr("cmd")
            for i = total_history, 1, -1 do
              local hist_cmd = vim.fn.histget("cmd", i)
              if vim.trim(hist_cmd) == trimmed then
                vim.fn.histdel("cmd", i)
              end
            end
            
            pcall(vim.cmd, "wshada!")
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
