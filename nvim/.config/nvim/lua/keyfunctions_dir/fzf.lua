local M = {}

M.fzf_command_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  -- 1. Nội dung các trang
  local page1 = [[
\033[1;34m=== CHEATSHEET (1/3): PHÍM TẮT CƠ BẢN ===\033[0m

  \033[32m<Enter>\033[0m     : Chạy lệnh được chọn (hoặc query nếu không khớp)
  \033[33m<Tab>\033[0m       : Thực thi ngay query đang gõ và lưu history
  \033[35m<Ctrl-z>\033[0m    : Đưa dòng đang chọn vào ô nhập để sửa
]]

  local page2 = [[
\033[1;33m=== CHEATSHEET (2/3): CLIPBOARD (COPYQ) ===\033[0m

  \033[36m<Ctrl-c>\033[0m    : Copy dòng đang chọn vào Clipboard
  \033[34m<Ctrl-v>\033[0m    : Paste từ Clipboard vào ô nhập hiện tại
]]

  local page3 = [[
\033[1;32m=== CHEATSHEET (3/3): ĐIỀU HƯỚNG ===\033[0m

  \033[31m<Ctrl-u/d>\033[0m  : Cuộn danh sách lệnh (nửa trang)
  \033[33m<?>\033[0m         : Bật / Tắt bảng Cheatsheet này
  \033[36m<Alt-Up/Dn>\033[0m: Đổi trang Cheatsheet qua lại
]]

  -- 2. Khởi tạo thư mục tạm
  local tmp_dir = vim.fn.tempname()
  vim.fn.mkdir(tmp_dir, "p")
  
  local function write_file(name, content)
    local path = tmp_dir .. "/" .. name
    local f = io.open(path, "w")
    if f then
      f:write(content)
      f:close()
    end
  end

  write_file("p1", (page1:gsub("\\033", "\27")))
  write_file("p2", (page2:gsub("\\033", "\27")))
  write_file("p3", (page3:gsub("\\033", "\27")))
  write_file("state", "1")

  -- Script nay phân chia rõ: update số trang và in trang
  local sh_script = [[
#!/bin/sh
dir="$1"
action="$2"
state_file="$dir/state"

v=$(cat "$state_file" 2>/dev/null || echo 1)
case "$v" in ''|*[!0-9]*) v=1 ;; esac

if [ "$action" = "next" ]; then
    v=$((v % 3 + 1))
    echo "$v" > "$state_file"
elif [ "$action" = "prev" ]; then
    v=$((v - 1))
    if [ "$v" -lt 1 ]; then v=3; fi
    echo "$v" > "$state_file"
fi

cat "$dir/p$v"
]]
  write_file("cycle.sh", sh_script)
  local cycle_path = tmp_dir .. "/cycle.sh"

  -- 3. Cấu hình Preview & Hành động (Fix logic FZF)
  -- Lệnh mặc định hiển thị trang
  local cmd_show = string.format("sh '%s' '%s' show", cycle_path, tmp_dir)
  
  -- Khi bấm phím: Tính trang mới ngầm (execute-silent) + Ép tải lại khung hiển thị (refresh-preview)
  local act_next = string.format("execute-silent(sh '%s' '%s' next)+refresh-preview", cycle_path, tmp_dir)
  local act_prev = string.format("execute-silent(sh '%s' '%s' prev)+refresh-preview", cycle_path, tmp_dir)

  fzf.command_history({
    winopts = { height = 0.5, width = 0.8, border = "rounded" },
    prompt = "Cmd History> ",
    header = ":: Bấm \27[33m<?>\27[0m Toggle Cheatsheet | \27[36m<Alt-Up/Down>\27[0m Đổi trang",
    
    fzf_opts = {
      ["--preview"] = cmd_show,
      ["--preview-window"] = "down:50%:hidden:wrap",
    },
    keymap = {
      fzf = {
        ["?"]         = "toggle-preview",
        
        -- Dùng cách ghép 2 hành động liên tiếp của FZF (cực kỳ mượt và không bị kẹt)
        ["alt-down"]  = act_next,
        ["alt-up"]    = act_prev,
        
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
