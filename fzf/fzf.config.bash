# ===============================================================
# FZF CONFIGURATION (Cấu hình cá nhân)
# ===============================================================

# ---------- 1. Giao diện (UI/UX) ----------
# --height: Chiếm 40% màn hình, không cho tràn hết
# --layout=reverse: Đưa thanh tìm kiếm lên phía trên (dễ nhìn hơn)
# --border: Vẽ khung cho sang trọng
# --info=inline: Hiển thị số lượng kết quả trên cùng dòng tìm kiếm
export FZF_DEFAULT_OPTS="
  --height 40% 
  --layout=reverse 
  --border 
  --margin=1 
  --padding=1
  --info=inline
  --color='header:italic,info:243,border:238'
"

# ---------- 2. Tùy chỉnh Phím tắt cụ thể ----------

# Khi nhấn CTRL-T (Tìm file): Hiện Preview nội dung file bên cạnh
# Nếu bạn chưa cài 'bat', hãy thay 'bat --color=always' bằng 'cat'
export FZF_CTRL_T_OPTS="
  --preview '[[ -f {} ]] && (bat --style=numbers --color=always {} || cat {}) | head -300'
  --preview-window=right:60%
"

# Khi nhấn ALT-C (Di chuyển thư mục): Hiện cây thư mục bên cạnh
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

# ---------- 3. Lệnh tìm kiếm mặc định (Dùng fd thay cho find) ----------
# 'fd' nhanh hơn 'find' gấp nhiều lần và tự bỏ qua .git, node_modules
if command -v fdfind > /dev/null; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --strip-cwd-prefix --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
elif command -v fd > /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# ---------- 4. Alias tiện ích ----------
# Tìm và mở file nhanh bằng Vim: gõ 'v' rồi chọn file
alias v='fzf --preview "bat --color=always --style=numbers {}" | xargs -r nvim'