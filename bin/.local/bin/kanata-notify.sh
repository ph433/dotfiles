#!/usr/bin/fish

sleep 1

nc localhost 1234 | while read -l line
    if test -n "$line"
        set LAYER (echo "$line" | jq -r '.ChangeLayer.new // .LayerChange.new // empty')
        
        if test -z "$LAYER"
            set LAYER "$line"
        end

        # Chỉ hiện khi sang layer mod_nvim (hoặc các layer khác base/default)
        if test "$LAYER" != "default" -a "$LAYER" != "base"
            # Truyền $LAYER trực tiếp làm Summary (Tiêu đề)
            notify-send -t 0 -h string:x-dunst-stack-tag:kanata "$LAYER"
        else
            # Nhả về layer mặc định thì đóng ô thông báo ngay
            dunstctl close
        end
    end
end
