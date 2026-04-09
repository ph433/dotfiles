# 1. Giao diện tối giản
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"

# 2. CTRL-R (Tìm lịch sử)
export FZF_CTRL_R_OPTS="--header 'History' --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'"

# 3. ALT-C (Nhảy thư mục - dùng fd để lọc rác .git)
if command -v fdfind > /dev/null; then
  export FZF_ALT_C_COMMAND='fdfind --type d --hidden --exclude .git'
elif command -v fd > /dev/null; then
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"

# 4. Đồng bộ lịch sử để CTRL-R hoạt động chuẩn
export HISTCONTROL=erasedups:ignoredups:ignorespace
shopt -s histappend
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"