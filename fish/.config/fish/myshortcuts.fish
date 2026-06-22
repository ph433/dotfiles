# ==========================================
# 1. HÀM CD VỀ DOTFILES (HOẶC THƯ MỤC CẤU HÌNH)
# ==========================================
function cdmd --description "CD nhanh ve thu muc duoc chi dinh"
    if not set -q MY_QUICK_DIR
        set -g MY_QUICK_DIR ~
    end

    cd $MY_QUICK_DIR

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

function lta --description "Hien thi cay thu muc chi tiet bang eza"
    eza --tree --level=2 --icons --group-directories-first -a --color=always $argv
end

function ll --description "Hien thi danh sach file chi tiet bang eza"
    eza -lah --icons --group-directories-first $argv
end
