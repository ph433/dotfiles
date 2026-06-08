function y --description "Mở Yazi và tự động CD về thư mục khi thoát"
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi --cwd-file="$tmp" $argv
    if set cwd (command cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end
