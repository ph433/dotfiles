local M = {}

M.fzf_fish_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  -- 1. Hàm nạp dữ liệu an toàn từ Fish shell vào fzf
  local function history_provider(fzf_cb)
    local lines = vim.fn.systemlist({
      "fish",
      "-c",
      "history merge; history | awk '!seen[$0]++'",
    })

    if vim.v.shell_error == 0 and type(lines) == "table" then
      for _, cmd in ipairs(lines) do
        local trimmed = vim.trim(cmd)
        if trimmed ~= "" then
          fzf_cb(trimmed)
        end
      end
    end
    fzf_cb(nil)
  end

  -- 2. Hàm chạy lệnh shell bên trong Neovim (:!cmd)
  local function run_shell_cmd(cmd_str)
    local trimmed = vim.trim(cmd_str or "")
    if #trimmed == 0 then return end

    vim.schedule(function()
      local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      local keys = ":!" .. trimmed .. cr
      vim.api.nvim_feedkeys(keys, "n", true)
    end)
  end

  -- 3. Tạo Cheatsheet Preview tạm thời
  local cheatsheet = [[
\27[1;34m=== FISH SHELL HISTORY IN NVIM ===\27[0m

\27[1;33m[ SHORTCUTS ]\27[0m
  \27[32m<Enter>\27[0m     : Execute shell command (:!cmd)
  \27[33m<Tab>\27[0m       : [Empty] Toggle Help | [Text] Run EXACT query
  \27[35m<Ctrl-z>\27[0m    : Clear query
  \27[31m<Ctrl-x>\27[0m    : Delete command from Fish history
  \27[36m<Ctrl-c>\27[0m    : Copy selected command to clipboard (CopyQ)
  \27[34m<Ctrl-v>\27[0m    : Paste from clipboard to search input
]]

  local cache_dir = vim.fn.stdpath("cache")
  local cheat_file = cache_dir .. "/fzf_fish_cheat.txt"
  local f = io.open(cheat_file, "w")
  if f then
    f:write((cheatsheet:gsub("\\27", string.char(27))))
    f:close()
  end

  local cmd_cheatsheet = "cat '" .. cheat_file .. "'"
  local tab_bind = string.format(
    [[transform:if [ -z "$FZF_QUERY" ]; then echo "change-preview(%s)+toggle-preview"; else echo 'become(echo alt-enter; printf "%%s\n" "$FZF_QUERY")'; fi]],
    cmd_cheatsheet
  )

  -- 4. Cấu hình fzf giao diện & keymaps
  local opts = {
    winopts = { height = 0.6, width = 0.85, border = "rounded" },
    prompt = "Fish History (!)> ",
    header = ":: <Enter> run (:!cmd) | <Tab> run query | <Ctrl-x> delete",

    fzf_opts = {
      ["--preview"] = cmd_cheatsheet,
      ["--tiebreak"] = "index",
      ["--preview-window"] = "down:50%:hidden:wrap",
      ["--color"] = "hl:yellow:reverse:bold,hl+:yellow:reverse:bold,pointer:#ff79c6,marker:#ff79c6,bg+:#44475a,spinner:#ff79c6",
    },

    keymap = {
      fzf = {
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
      -- Enter: Chạy lệnh được chọn qua :!
      ["default"] = function(selected, act_opts)
        local query = (act_opts and (act_opts.last_query or act_opts.query)) or ""
        local selected_item = (selected and selected[1]) or ""
        local cmd = (selected_item ~= "") and selected_item or query
        run_shell_cmd(cmd)
      end,

      -- Tab khi có text: Chạy trực tiếp query
      ["alt-enter"] = function(selected, _)
        local query = (selected and selected[1]) or ""
        run_shell_cmd(query)
      end,

      -- Ctrl-X: Xóa lệnh khỏi Fish history và tự load lại danh sách
      ["ctrl-x"] = {
        fn = function(selected, _)
          local item = (selected and selected[1]) or ""
          local trimmed = vim.trim(item)
          if #trimmed == 0 then return end

          -- Backup vào clipboard/CopyQ trước khi xóa
          vim.fn.setreg("+", trimmed)
          vim.fn.system({ "copyq", "add", "-" }, trimmed)

          -- Xóa trực tiếp trong fish database
          vim.fn.system({
            "fish",
            "-c",
            "history delete --exact --case-sensitive " .. vim.fn.shellescape(trimmed) .. "; history save",
          })
        end,
        noclose = true,
        reload = true,
      },
    },
  }

  fzf.fzf_exec(history_provider, opts)
end

return M
