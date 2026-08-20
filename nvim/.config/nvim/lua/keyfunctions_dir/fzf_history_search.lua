local M = {}

M.fzf_search_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  -- 1. HÀM CUNG CẤP DỮ LIỆU ĐỘNG: Lấy lịch sử tìm kiếm ("search")
  local function history_provider(fzf_cb)
    local total_history = vim.fn.histnr("search")
    for i = total_history, 1, -1 do
      local query = vim.fn.histget("search", i)
      if query ~= "" then
        fzf_cb(query)
      end
    end
    fzf_cb(nil)
  end

  local cheatsheet = [[
\27[1;34m=== FZF SEARCH HISTORY CHEATSHEET ===\27[0m

\27[1;33m[ 1. BASIC SHORTCUTS ]\27[0m
  \27[32m<Enter>\27[0m     : Search selected pattern (or query if no match)
  \27[33m<Tab>\033[0m       : [Empty] Toggle Help | [Text] Run EXACT pattern
  \27[35m<Ctrl-z>\033[0m    : Put selected pattern into input to edit
  \27[31m<Ctrl-a>\033[0m    : Clear entire query input

\27[1;33m[ 2. CLIPBOARD & DELETE ]\27[0m
  \27[36m<Ctrl-c>\033[0m    : Copy selected pattern to clipboard
  \27[34m<Ctrl-x>\033[0m    : Copy & delete pattern from search history
  \27[34m<Ctrl-v>\033[0m    : Paste from Clipboard to input

\27[1;33m[ 3. NAVIGATION ]\27[0m
  \27[31m<Ctrl-up/down>\033[0m: Scroll list (half page up/down)
  \27[33m<?>\033[0m         : Toggle this Cheatsheet
  \27[36m<;>\033[0m         : Toggle Hello Preview
]]

  local hello_txt = "\\27[1;32m=== HELLO ===\\27[0m\n\nHello! This is search history preview."

  local cache_dir = vim.fn.stdpath("cache")
  local cheat_file = cache_dir .. "/fzf_search_cheat.txt"
  local hello_file = cache_dir .. "/fzf_search_hello.txt"

  local f1 = io.open(cheat_file, "w")
  if f1 then f1:write((cheatsheet:gsub("\\27", string.char(27)))); f1:close() end

  local f2 = io.open(hello_file, "w")
  if f2 then f2:write((hello_txt:gsub("\\27", string.char(27)))); f2:close() end

  local cmd_cheatsheet = "cat " .. cheat_file
  local cmd_hello = "cat " .. hello_file

  local opts = {
    winopts = { height = 0.55, width = 0.8, border = "rounded" },
    prompt = "Search History> ",
    header = ":: <Enter> search | <Ctrl-z> edit | <Ctrl-x> copy & del | <Ctrl-c> copy",

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

        ["tab"]       = string.format([[transform:sh -c 'if [ -z "$FZF_QUERY" ]; then echo "change-preview(%s)+toggle-preview"; else echo "become(echo; echo \"$FZF_QUERY\")"; fi']], cmd_cheatsheet),
        ["enter"]     = "accept",

        ["ctrl-a"]    = "clear-query",
        ["ctrl-z"]    = "transform-query(echo -n {})",
        ["ctrl-up"]   = "half-page-up",
        ["ctrl-down"] = "half-page-down",
        ["ctrl-v"]    = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\\r\\n')\")",

        ["ctrl-c"]    = "execute-silent(echo -n {} | copyq add - && copyq select 0)",
      },
    },

    actions = {
      -- 1. Khi ấn Enter: Thực hiện tìm kiếm pattern vừa chọn (/pattern<CR>)
      ["default"] = function(selected, opts)
        local pattern = ""
        local selected_item = (selected and selected[1]) or ""
        local query = opts.query or opts.last_query or ""

        if selected and selected[2] and selected[2] ~= "" then
          pattern = selected[2]
        elseif selected_item ~= "" then
          pattern = selected_item
        else
          pattern = query
        end

        local trimmed = vim.trim(pattern)
        if #trimmed > 0 then
          vim.schedule(function()
            -- Lưu lại vào lịch sử search
            vim.fn.histadd("search", trimmed)
            -- Gán vào thanh ghi tìm kiếm và kích hoạt tìm kiếm
            vim.fn.setreg("/", trimmed)
            local keys = vim.api.nvim_replace_termcodes("/" .. trimmed .. "<CR>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", true)
          end)
        end
      end,

      -- 2. Ctrl-X: Copy vào copyq/clipboard + Xóa chính xác khỏi lịch sử search và reload GUI
      ["ctrl-x"] = {
        fn = function(selected, _)
          local item = (selected and selected[1]) or ""
          local trimmed = vim.trim(item)
          if #trimmed > 0 then
            -- Copy vào clipboard & CopyQ
            vim.fn.setreg("+", trimmed)
            vim.fn.setreg('"', trimmed)
            vim.fn.system({ "copyq", "add", "-" }, trimmed)
            vim.fn.system({ "copyq", "select", "0" })

            -- Xóa đúng 1 pattern khỏi lịch sử tìm kiếm Neovim
            local exact_match = "^" .. vim.fn.escape(trimmed, "\\/.*$^~[]") .. "$"
            vim.fn.histdel("search", exact_match)
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
