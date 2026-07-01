function _fzf_search_history_custom --description "Search command history. Replace the command line with the selected command."
    if test -z "$fish_private_mode"
        builtin history merge
    end

    if not set --query fzf_history_time_format
        set -f fzf_history_time_format "%m-%d %H:%M:%S"
    end

    set -f time_prefix_regex '^.*? │ '
    
    # Dùng `string sub -s 2` để cắt bỏ chính xác 1 dấu cách thừa do delimiter `│` để lại
    set -f delete_cmd "execute-silent(history delete --exact --case-sensitive -- (string sub -s 2 -- {2..}))+reload($reload_cmd)"
    
    set -f fzf_out (
        builtin history --null --show-time="$fzf_history_time_format │ " |
        _fzf_wrapper --read0 \
	    --print0 \
            --multi \
            --tac \
            --tiebreak=index \
            --prompt="History> " \
            --query=(commandline) \
            --delimiter="│" \
            --nth=2.. \
            --no-height \
            --layout=reverse-list \
            $fzf_history_opts \
            --preview=$preview_cmd \
            --preview-window="top:35%:wrap:border-bottom" \
            --select-1 \
            --expect=right,enter \
            --bind="start:last,right:accept,left:$delete_cmd" |
        string split0
    )

    # ---------------------------------------------------------
    # 4. XỬ LÝ HÀNH ĐỘNG SAU KHI THOÁT FZF
    # ---------------------------------------------------------
    if test $status -eq 0
        set -l key_pressed $fzf_out[1]
        set -l commands_selected $fzf_out[2..-1]
        
        set commands_selected (string replace --regex $time_prefix_regex '' $commands_selected)
        
        commandline --replace -- $commands_selected
        
        if test "$key_pressed" = "enter"
            commandline --function execute
        end
    end

    commandline --function repaint
end
