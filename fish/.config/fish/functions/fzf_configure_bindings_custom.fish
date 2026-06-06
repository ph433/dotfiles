function fzf_configure_bindings_custom --description "Installs bindings for fzf.fish with directory and find_files custom overrides"
    # Không chạy nếu không ở chế độ tương tác
    status is-interactive || test "$CI" = true; or return

    # ĐÃ THÊM 'find_files=?' VÀO ĐÂY ĐỂ ĐỌC CỜ MỚI
    set -f options_spec h/help 'directory=?' 'find_files=?' 'git_log=?' 'git_status=?' 'history=?' 'processes=?' 'variables=?'
    argparse --max-args=0 --ignore-unknown $options_spec -- $argv 2>/dev/null
    
    if test $status -ne 0
        echo "Invalid option or a positional argument was provided." >&2
        return 22
    else if set --query _flag_help
        echo "Hàm custom hỗ trợ gán phím tắt cho cả directory và find_files."
        return
    else
        # Khởi tạo mớ phím tắt (Mục số 2 dành cho find_files, tạm để trống mặc định)
        # index 1 = directory, 2 = find_files, 3 = git_log, 4 = git_status, 5 = history, 6 = processes, 7 = variables
        set -f key_sequences ctrl-alt-f "" ctrl-alt-l ctrl-alt-s ctrl-r ctrl-alt-p ctrl-v
        
        # Đọc các cờ bạn truyền vào từ config.fish
        set --query _flag_directory && set key_sequences[1] "$_flag_directory"
        set --query _flag_find_files && set key_sequences[2] "$_flag_find_files" # ĐỒNG BỘ CỜ MỚI
        set --query _flag_git_log && set key_sequences[3] "$_flag_git_log"
        set --query _flag_git_status && set key_sequences[4] "$_flag_git_status"
        set --query _flag_history && set key_sequences[5] "$_flag_history"
        set --query _flag_processes && set key_sequences[6] "$_flag_processes"
        set --query _flag_variables && set key_sequences[7] "$_flag_variables"

        # Nếu đã có phím tắt cũ, gỡ sạch để làm lại từ đầu
        if functions --query _fzf_uninstall_bindings_custom
            _fzf_uninstall_bindings_custom
        end

        # VÒNG LẶP GÁN PHÍM TẮT CHO CẢ DEFAULT VÀ INSERT MODE
        for mode in default insert
            # 1. Trỏ vào hàm Tìm thư mục custom của bạn
            test -n $key_sequences[1] && bind --mode $mode $key_sequences[1] __fzf_search_directory_custom
            
            # 2. ĐÃ THÊM TẠI ĐÂY: Trỏ vào hàm Tìm file phẳng custom của bạn
            test -n $key_sequences[2] && bind --mode $mode $key_sequences[2] __fzf_find_files_custom
            
            # Các phím tắt khác của plugin giữ nguyên
            test -n $key_sequences[3] && bind --mode $mode $key_sequences[3] _fzf_search_git_log
            test -n $key_sequences[4] && bind --mode $mode $key_sequences[4] _fzf_search_git_status
            test -n $key_sequences[5] && bind --mode $mode $key_sequences[5] _fzf_search_history
            test -n $key_sequences[6] && bind --mode $mode $key_sequences[6] _fzf_search_processes
            test -n $key_sequences[7] && bind --mode $mode $key_sequences[7] "$_fzf_search_vars_command"
        end

        # Hàm gỡ phím tắt custom
        function _fzf_uninstall_bindings_custom --inherit-variable key_sequences
            bind --erase -- $key_sequences
            bind --erase --mode insert -- $key_sequences
        end
    end
end
