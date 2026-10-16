local M = {}

-- 1. Hàm tính relative time thuần túy
function M.time_ago(timestamp, now)
  now = now or os.time()
  local ts = tonumber(timestamp)
  if not ts then return "unknown" end

  local diff = math.max(0, now - ts)
  if diff < 60 then
    return string.format("%ds ago", diff)
  elseif diff < 3600 then
    return string.format("%dm ago", math.floor(diff / 60))
  elseif diff < 86400 then
    return string.format("%dh ago", math.floor(diff / 3600))
  elseif diff < 604800 then
    return string.format("%dd ago", math.floor(diff / 86400))
  elseif diff < 2592000 then
    return string.format("%dw ago", math.floor(diff / 604800))
  elseif diff < 31536000 then
    return string.format("%dmo ago", math.floor(diff / 2592000))
  else
    return string.format("%dy ago", math.floor(diff / 31536000))
  end
end

-- 2. Hàm format entry tổng quát (cho phép tùy biến màu ANSI)
-- ansi_color mặc định là Cyan (1;36m) nếu không truyền
function M.format_log_entry(raw_entry, now, ansi_color, is_current)
  ansi_color = ansi_color or "\27[1;36m"
  local flag = is_current and "#" or " "
  local ts_str, path = raw_entry:match("^(%d+)%s+(.+)$")

  if not ts_str then
    return string.format("%8s %s │ %s", "unknown", flag, vim.fs.normalize(raw_entry))
  end

  local ago_str = string.format("%8s", M.time_ago(ts_str, now))
  -- local colored_ago = string.format("%s%s\27[0m", ansi_color, ago_str)
  local colored_ago = string.format("%s", ago_str)

  return string.format("%s %s │ %s", colored_ago, flag, vim.fs.normalize(path))
end

return M
