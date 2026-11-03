#!/usr/bin/env python3
import subprocess
import json
import socket
import re
import threading

def set_kanata_layer(layer_name):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(0.05)
            s.connect(("127.0.0.1", 1234))
            payload = json.dumps({"ChangeLayer": {"new": layer_name}}) + "\n"
            s.sendall(payload.encode('utf-8'))
    except Exception:
        pass

def get_window_info(win_id):
    try:
        output = subprocess.check_output(
            ["xprop", "-id", str(win_id), "WM_CLASS", "WM_NAME"], 
            stderr=subprocess.DEVNULL
        ).decode('utf-8', errors='ignore')
        
        win_class = ""
        win_title = ""
        
        for line in output.splitlines():
            if "WM_CLASS" in line:
                win_class = line.split("=")[1].strip()
            elif "WM_NAME" in line:
                win_title = line.split("=")[1].strip().strip('"')
                
        return win_class, win_title
    except Exception:
        return "", ""

def determine_layer(win_class, win_title):
    wc = win_class.lower()
    wt = win_title.lower()

    # 1. ƯU TIÊN KIỂM TRA TIÊU ĐỀ TRƯỚC
    # Chỉ bắt chữ "vis" nếu nó đứng đầu (vis file.txt) hoặc có dấu cách (vis - file)
    # Tránh bắt nhầm đường dẫn thư mục ~/.c/vis
    if wt.startswith("vis") or " vis " in wt or "vis -" in wt:
        return "mod_nvim"
    if wt.startswith("nvim") or " nvim " in wt:
        return "mod_nvim"
    if "python" in wt:
        return "mod_python"

    # 2. KIỂM TRA CLASS
    if "firefox" in wc:
        return "mod_firefox"
    if "qutebrowser" in wc:
        return "mod_qutebrowser"

    # 3. Mặc định
    return "base"

def listen_to_event(event_name):
    process = subprocess.Popen(
        ["dwm-msg", "subscribe", event_name],
        stdout=subprocess.PIPE,
        text=True
    )

    for line in process.stdout:
        line = line.strip()
        if not line:
            continue

        # Regex bắt ID của cửa sổ (hỗ trợ cả new_win_id và client_window_id)
        match = re.search(r'"(?:new_win_id|client_window_id)":\s*(\d+)', line)
        
        if match:
            win_id = match.group(1)
            win_class, win_title = get_window_info(win_id)
            layer = determine_layer(win_class, win_title)
            set_kanata_layer(layer)
            print(f"✅ [KẾT QUẢ] Class: {win_class} | Title: {win_title} -> Layer: {layer}", flush=True)

def main():
    print("Đang lắng nghe sự kiện từ dwm-ipc...", flush=True)
    # Chạy 2 luồng riêng biệt để bắt sự kiện
    t1 = threading.Thread(target=listen_to_event, args=("client_focus_change_event",))
    t2 = threading.Thread(target=listen_to_event, args=("focused_title_change_event",))
    
    t1.daemon = True
    t2.daemon = True
    
    t1.start()
    t2.start()
    
    try:
        t1.join()
        t2.join()
    except KeyboardInterrupt:
        print("\nĐã thoát.")

if __name__ == "__main__":
    main()
