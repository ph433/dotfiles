function log_recent_file -d "Ghi log recent file"
    set -l target_file $argv[1]
    test -z "$target_file"; and return
    
    if test -f "$target_file"
        set -l timestamp (date +%s)
        echo "$timestamp $target_file" >> "$HOME/.cache/nvim_recent.log"
    end
end
