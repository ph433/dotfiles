function __fzf_scan_paths --argument-names level scan_type
    set -l real_pwd (realpath $PWD)
    set -l common_excludes --exclude .git --exclude node_modules --exclude .cache --exclude .local/share --exclude target --exclude build

    # Default type to file if not provided
    test -z "$scan_type"; and set scan_type "f"

    switch $level
        case 1
            # Cấp 1: Hiện tại - KHÔNG quét sâu (--max-depth 1)
            fd --type $scan_type --hidden --follow $common_excludes --max-depth 1 . "$real_pwd"
        case 2
            # Cấp 2: Quét SÂU tính từ thư mục hiện tại
            fd --type $scan_type --hidden --follow $common_excludes . "$real_pwd"
        case 3
            # Cấp 3: Quét SÂU từ $HOME
            fd --type $scan_type --hidden --follow $common_excludes . "$HOME"
    end
end
