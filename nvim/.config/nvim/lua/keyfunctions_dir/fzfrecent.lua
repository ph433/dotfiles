local M = {}
local fzf = require("fzf-lua")

local LOG_FILE = vim.fs.normalize("~/.cache/nvim_recent.log")

-- 1. FORMAT CHUỖI UI
function M._format_entry(raw_entry, now)
  local ts_str, path = raw_entry:match("^(%d+)%s+(.+)$")
  if not ts_str then
    return string.format("%8s │ %s", "unknown", vim.fs.normalize(raw_entry))
  end

  local diff = math.max(0, now - tonumber(ts_str))
  local raw_ago
  if diff < 60 then
    raw_ago = string.format("%ds ago", diff)
  elseif diff < 3600 then
    raw_ago = string.format("%dm ago", math.floor(diff / 60))
  elseif diff < 86400 then
    raw_ago = string.format("%dh ago", math.floor(diff / 3600))
  elseif diff < 604800 then
    raw_ago = string.format("%dd ago", math.floor(diff / 86400))
  elseif diff < 2592000 then
    raw_ago = string.format("%dw ago", math.floor(diff / 604800))
  elseif diff < 31536000 then
    raw_ago = string.format("%dmo ago", math.floor(diff / 2592000))
  else
    raw_ago = string.format("%dy ago", math.floor(diff / 31536000))
  end

  return string.format("\27[1;36m%8s\27[0m │ %s", raw_ago, vim.fs.normalize(path))
end

-- 2. ĐỌC FILE SYNC
local function get_recent_entries()
  local f = io.open(LOG_FILE, "r")
  if not f then return {} end

  local content = f:read("*a")
  f:close()
  if not content or content == "" then return {} end

  local lines = vim.split(content, "\n", { trimempty = true })
  local total_lines = #lines
  if total_lines == 0 then return {} end

  local seen = {}
  local items = {}
  local count = 0
  local limit = 50
  local now = os.time()

  for i = total_lines, 1, -1 do
    local entry = lines[i]
    local path = entry:match("^%d+%s+(.+)$") or entry
    if not seen[path] then
      seen[path] = true
      count = count + 1
      table.insert(items, M._format_entry(entry, now))
      if count >= limit then break end
    end
  end

  return items
end

-- 3. ACTIONS
local function extract_paths(selected)
  local paths = {}
  for _, line in ipairs(selected) do
    local p = line:match("│%s*(.+)$")
    if p then table.insert(paths, p) end
  end
  return paths
end

M.actions = {
  ["default"] = function(selected)
    local paths = extract_paths(selected)
    if #paths == 0 then return end
    for _, path in ipairs(paths) do
      vim.cmd.badd(vim.fn.fnameescape(path))
    end
    vim.cmd.edit(vim.fn.fnameescape(paths[1]))
  end,
}

-- 4. HÀM ĐIỀU PHỐI CHÍNH
function M.fzfrecent()
  local items = get_recent_entries()
  if #items == 0 then return end

  -- Cheatsheet preview (đồng bộ style fzf_buffers)
  local cheatsheet = [[
\27[1;34m=== FZF RECENT PICKER CHEATSHEET ===\27[0m

\27[1;33m[ 1. NAVIGATION & ACTIONS ]\27[0m
  \27[32m<Enter>\27[0m     : Mở file đã chọn
  \27[33m<Tab>\27[0m       : Đóng / mở cheatsheet trợ giúp
  \27[35m<Ctrl-z>\27[0m     : Xóa nhanh query tìm kiếm

\27[1;33m[ 2. CLIPBOARD (COPYQ) ]\27[0m
  \27[36m<Ctrl-c>\27[0m     : Sao chép đường dẫn file vào CopyQ
  \27[34m<Ctrl-v>\27[0m     : Dán nội dung Clipboard vào ô tìm kiếm
]]

  local cache_dir = vim.fn.stdpath("cache")
  local cheat_file = cache_dir .. "/fzf_recent_cheat.txt"

  local f1 = io.open(cheat_file, "w")
  if f1 then
    f1:write((cheatsheet:gsub("\\27", string.char(27))))
    f1:close()
  end

  local cmd_cheatsheet = "cat '" .. cheat_file .. "'"
  local tab_bind = string.format("change-preview(%s)+toggle-preview", cmd_cheatsheet)

  fzf.fzf_exec(items, {
    winopts = { height = 0.55, width = 0.8, border = "rounded" },
    prompt = "Recent> ",
    header = ":: <Enter> open | <Tab> help | <Ctrl-c> copy path | <Ctrl-v> paste",

    fzf_opts = {
      ["--multi"] = true,
      ["--ansi"] = true,
      ["--delimiter"] = "│",
      ["--nth"] = "2..",
      ["--tiebreak"] = "index",
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
        ["ctrl-v"]    = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\\r\\n')\")",
        ["ctrl-c"]    = [[execute-silent(echo -n {} | awk -F '│ ' '{print $2}' | tr -d '\n' | copyq add - && copyq select 0)]],
        ["ctrl-z"]    = "clear-query",
      },
    },

    actions = M.actions,
  })
end

return M
