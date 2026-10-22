function run_cmd_to_clipboard
    set -l cmd (commandline)
    test -z "$cmd"; and return

    echo "" # Xuống dòng để không đè prompt

    # Chạy qua POSIX sh ở background, ngắt hoàn toàn I/O để không block terminal
    sh -c "$cmd 2>&1 | copyq add - && copyq select 0" >/dev/null 2>&1 &
    disown 2>/dev/null

    # Trả lại prompt sạch ngay lập tức
    commandline -r ""
    commandline -f repaint
end
