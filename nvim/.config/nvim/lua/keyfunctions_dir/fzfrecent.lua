local M = {}
local uv = vim.uv or vim.loop
local fzf = require("fzf-lua")

local LOG_FILE = vim.fs.normalize("~/.cache/nvim_recent.log")

local function await(async_fn, a, b, c)
  local co = coroutine.running()
  local function resume_cb(...)
    coroutine.resume(co, ...)
  end

  if c ~= nil then
    async_fn(a, b, c, resume_cb)
  elseif b ~= nil then
    async_fn(a, b, resume_cb)
  elseif a ~= nil then
    async_fn(a, resume_cb)
  else
    async_fn(resume_cb)
  end

  return coroutine.yield()
end

-- =======================================================================
-- 1. TƯƠNG ĐƯƠNG: _fzfrecent_get_top10
-- Đọc log, deduplicate và kiểm tra file tồn tại non-blocking
-- =======================================================================
function M._get_top_entries(limit)
  limit = limit or 50
  local err_open, fd = await(uv.fs_open, LOG_FILE, "r", 438)
  if err_open or not fd then return {} end

  local err_stat, stat = await(uv.fs_fstat, fd)
  if err_stat or not stat or stat.size == 0 then
    uv.fs_close(fd)
    return {}
  end

  local err_read, data = await(uv.fs_read, fd, stat.size, 0)
  uv.fs_close(fd)
  if err_read or not data or data == "" then return {} end

  local lines = vim.split(data, "\n", { trimempty = true })
  local total_lines = #lines
  if total_lines == 0 then return {} end

  local seen = {}
  local candidates = {}

  for i = total_lines, 1, -1 do
    local entry = lines[i]
    local path = entry:match("^%d+%s+(.+)$") or entry
    -- path = vim.fs.normalize(path)

    if not seen[path] then
      seen[path] = true
      table.insert(candidates, { raw = entry, path = path })
      if #candidates >= limit then break end
    end
  end

  if #candidates == 0 then return {} end

  -- Stat kiểm tra file tồn tại song song
  local valid_entries = {}
  local pending = #candidates
  local co = coroutine.running()

  for idx, item in ipairs(candidates) do
    uv.fs_stat(item.path, function(_, item_stat)
      if item_stat then
        table.insert(valid_entries, { order = idx, item = item })
      end
      pending = pending - 1
      if pending == 0 then coroutine.resume(co) end
    end)
  end
  coroutine.yield()

  table.sort(valid_entries, function(a, b) return a.order < b.order end)

  local resolved = {}
  for _, v in ipairs(valid_entries) do
    table.insert(resolved, v.item)
  end

  -- Dọn log nếu quá dài
  if total_lines > 100 and #resolved > 0 then
    local clean_lines = {}
    for i = #resolved, 1, -1 do
      table.insert(clean_lines, resolved[i].raw)
    end
    local out_err, out_fd = await(uv.fs_open, LOG_FILE, "w", 438)
    if not out_err and out_fd then
      local payload = table.concat(clean_lines, "\n") .. "\n"
      await(uv.fs_write, out_fd, payload, 0)
      uv.fs_close(out_fd)
    end
  end

  return resolved
end

-- =======================================================================
-- 2. TƯƠNG ĐƯƠNG: _fzfrecent_format_list
-- Format chuỗi UI (relative time + delimiter)
-- =======================================================================
function M._format_entry(raw_entry, now)
  local ts_str, path = raw_entry:match("^(%d+)%s+(.+)$")
  if not ts_str then
    return string.format("%8s │ %s", "unknown", vim.fs.normalize(raw_entry))
  end

  local diff = now - tonumber(ts_str)
  if diff < 0 then diff = 0 end

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

  local padded_ago = string.format("%8s", raw_ago)
  local colored_ago = string.format("\27[1;30m%s\27[0m", padded_ago)

  return string.format("%s │ %s", colored_ago, vim.fs.normalize(path))
end

-- =======================================================================
-- 3. TƯƠNG ĐƯƠNG: Switch-case Action Handler trong Fish
-- Tách paths từ selected items và thực hiện action tương ứng
-- =======================================================================
local function extract_paths(selected)
  local paths = {}
  for _, line in ipairs(selected) do
    local p = line:match("│%s*(.+)$")
    if p then table.insert(paths, p) end
  end
  return paths
end

M.actions = {
  -- Enter: Mở tất cả buffers đã chọn (buffer đầu tiên được hiển thị)
  ["default"] = function(selected)
    local paths = extract_paths(selected)
    if #paths == 0 then return end
    for _, path in ipairs(paths) do
      vim.cmd.badd(vim.fn.fnameescape(path))
    end
    vim.cmd.edit(vim.fn.fnameescape(paths[1]))
  end,
}

-- =======================================================================
-- 4. TƯƠNG ĐƯƠNG: function fzfrecent (Hàm điều phối chính)
-- =======================================================================
function M.fzfrecent()
  local function provider(fzf_cb)
    coroutine.wrap(function()
      local entries = M._get_top_entries(50)
      if #entries == 0 then
        fzf_cb(nil)
        return
      end

      local now = os.time()
      for _, item in ipairs(entries) do
        fzf_cb(M._format_entry(item.raw, now))
      end
      fzf_cb(nil)
    end)()
  end

  fzf.fzf_exec(provider, {
    prompt = "🕒 Nvim Recent (Tab để chọn nhiều)> ",
    fzf_opts = {
      ["--multi"] = true,
      ["--ansi"] = true,
      ["--delimiter"] = "│",
      ["--nth"] = "2..",
      ["--tiebreak"] = "index",
      ["--preview-window"] = "bottom:70%",
      ["--layout"] = "reverse",
    },
    previewer = {
      _ctor = function()
        local builtin = require("fzf-lua.previewer.builtin")
        local MyPreviewer = builtin.buffer_or_file:extend()

        function MyPreviewer:parse_entry(entry_str)
          local p = entry_str:match("│%s*(.+)$")
          return {
            path = p or entry_str,
          }
        end

        return MyPreviewer
      end,
    },
    actions = M.actions,
  })
end -- <-- THÊM CHỮ END NÀY Ở ĐÂY ĐỂ ĐÓNG M.fzfrecent()

return M
