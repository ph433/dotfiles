# ==========================================
# 1. HÀM CD VỀ DOTFILES (HOẶC THƯ MỤC CẤU HÌNH)
# ==========================================
function cdmd --description "CD nhanh ve thu muc duoc chi dinh"
    if not set -q MY_QUICK_DIR
        set -g MY_QUICK_DIR ~
    end

    cd $MY_QUICK_DIR

    if type -q zoxide
        zoxide add $MY_QUICK_DIR
    end
    
    commandline -f repaint
end

# ==========================================
# 2. HÀM CD VỀ HOME (Z ~)
# ==========================================
function cdh --description "CD nhanh ve thu muc Home"
    # Thực hiện lệnh z ~ (hoặc cd ~ nếu không có zoxide)
    if type -q zoxide
        z $HOME
    else
        cd $HOME
    end
    
    commandline -f repaint
end

