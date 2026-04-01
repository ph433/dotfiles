# ===============================================================
# 0. QUẢN LÝ LỊCH SỬ LỆNH (Sạch sẽ - Không trùng lặp - Bất tử)
# ===============================================================
export HISTSIZE=10000                   # Số lệnh lưu trong RAM
export HISTFILESIZE=20000                # Số lệnh lưu trong file .bash_history

# erasedups: Xóa sạch các bản trùng cũ trong quá khứ khi gõ lệnh mới
# ignorespace: Không lưu lệnh nếu bắt đầu bằng dấu cách (để bảo mật)
# ignoredups: Không lưu lệnh nếu gõ trùng liên tiếp
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Thần chú đồng bộ: Ghi ngay, xóa đệm cũ và nạp lại để các Tab luôn thấy lệnh mới của nhau
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# Cho phép gộp lịch sử thay vì ghi đè khi đóng Terminal
shopt -s histappend

# ===============================================================
# 1. FZF CONFIGURATION (Giao diện chuẩn Power User)
# ===============================================================
export FZF_DEFAULT_OPTS="
  --height 60%
  --layout=reverse
  --border=rounded
  --margin=1,2
  --padding=0
  --info=inline
  --marker='* '
  --pointer='▶'
  --color='header:italic,info:243,border:238,prompt:110,pointer:167,marker:214'
  --bind 'ctrl-u:preview-page-up,ctrl-d:preview-page-down'
"

# ---------- 2. Tùy chỉnh Phím tắt cụ thể ----------

# CTRL-R (Tìm lịch sử): Bỏ sắp xếp để giữ thứ tự thời gian, gõ đến đâu lọc đến đó
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window=down:3:hidden:wrap
  --header ' [CTRL-Y: Copy lệnh] '
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'
"

# CTRL-T (Tìm file): Preview nội dung file thông minh
export FZF_CTRL_T_OPTS="
  --preview '[[ -f {} ]] && (batcat --style=numbers --color=always {} || bat --style=numbers --color=always {} || cat {}) | head -300'
  --preview-window=right:60%
  --header ' [TAB: Chọn nhiều file] '
"

# ALT-C (Di chuyển thư mục): Hiện cây thư mục (yêu cầu cài 'tree')
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

# ---------- 3. Lệnh tìm kiếm mặc định (Dùng fd để tốc độ bàn thờ) ----------
# Ưu tiên fdfind (Ubuntu/Mint) hoặc fd (Arch/Fedora)
if command -v fdfind > /dev/null; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --strip-cwd-prefix --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
elif command -v fd > /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# ===============================================================
# 4. ALIASES TIỆN ÍCH (Workflow tăng năng suất)
# ===============================================================

# Mở file bằng Neovim (v): Tự lọc rác, cho phép chọn nhiều file bằng TAB
alias v='fzf --multi --header "Chọn file để mở bằng Neovim" --preview "(batcat --color=always --style=numbers {} || bat --color=always --style=numbers {} || cat {})" | xargs -r nvim'

# Tìm và di chuyển vào thư mục nhanh (cd)
alias cdd='cd "$(find . -maxdepth 3 -type d | fzf --header "Di chuyển đến thư mục")"'

# Dọn dẹp file .bash_history (Chạy cái này nếu file cũ còn quá nhiều lệnh trùng)
alias hist-clean='awk -i inplace "!seen[\$0]++" ~/.bash_history && history -c && history -r'