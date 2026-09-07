function _fzfrecent_feed -d "Lấy và định dạng danh sách cho FZF UI"
    set -l log_file $argv[1]
    set -l top_files (_fzfrecent_get_top_generic "$log_file")
    
    if test (count $top_files) -gt 0
        _fzfrecent_format_list $top_files
    end
    return 0
end
