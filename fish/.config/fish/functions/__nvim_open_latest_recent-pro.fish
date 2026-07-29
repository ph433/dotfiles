function __nvim_open_func_source-pro
    # Lấy toàn bộ nội dung dòng lệnh hiện tại
    set -l raw_cmd (commandline -b | string trim)
    set -l target_func ""

    # Trường hợp 1: Nếu dòng lệnh trống hoặc chỉ gõ chữ bind chung chung -> Cho chọn tất cả các hàm
    if test -z "$raw_cmd"; or test "$raw_cmd" = "bind"
        if type -q fzf
            set target_func (functions -n | fzf --prompt="🔍 Chọn hàm Fish để chỉnh sửa: " --height=40% --layout=reverse --border)
        else
            echo -e "\n[Lỗi] Bạn cần cài đặt 'fzf' để sử dụng tính năng tìm kiếm danh sách!"
            commandline -f repaint
            return 1
        end
    # Trường hợp 2: Nếu người dùng gõ lệnh bind (Ví dụ: "bind left", "bind \cx")
    else if string match -q "bind *" "$raw_cmd"
        # Chạy lệnh eval bind ngầm để xem phím đó đang liên kết với hàm nào
        set -l bind_output (eval $raw_cmd 2>/dev/null)
        # Bóc tách tên hàm nằm sau phím tắt
        set target_func (echo $bind_output | string match -r '(?<=\s)[a-zA-Z0-9_-]+$')
    # Trường hợp 3: Người dùng gõ trực tiếp tên hàm hoặc từ khóa
    else
        # Thử lấy từ đầu tiên trên dòng lệnh trước
        set -l first_word (string split -m 1 ' ' -- $raw_cmd)[1]
        
        if functions -q $first_word
            set target_func $first_word
        else if type -q fzf
            # Nếu từ đầu tiên không phải hàm chuẩn, dùng fzf lọc danh sách các hàm chứa từ khóa đó
            set target_func (functions -n | string match -r ".*$first_word.*" | fzf --query="$first_word" --prompt="🔍 Tìm thấy nhiều hàm phù hợp: " --height=40% --layout=reverse --border)
        end
    end

    # Tiến hành mở file bằng nvim nếu tìm thấy hàm hợp lệ
    if test -n "$target_func"; and functions -q $target_func
        set -l func_file (functions --details $target_func)

        if test -f "$func_file"
            commandline -r "" # Xóa dòng lệnh cũ để tránh rác màn hình
            nvim $func_file
            commandline -f repaint
        else
            echo -e "\n[Lỗi] Hàm '$target_func' được định nghĩa trực tiếp, không có file lưu trữ."
            commandline -f repaint
        end
    else
        if test -n "$target_func"
            echo -e "\n[Lỗi] '$target_func' không phải là một hàm Fish shell hợp lệ!"
        end
        commandline -f repaint
    end
end

