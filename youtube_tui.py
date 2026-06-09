#!/usr/bin/env python3
import curses
import subprocess
import json
import os
import tempfile
import threading
import time
import sys

# --- CẤU HÌNH CƠ BẢN ---
SEARCH_QUERY = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "lofi chill"
COLUMNS = 3        # Số cột trong lưới (Grid)
ROWS = 2           # Số hàng trong lưới
PAGE_SIZE = COLUMNS * ROWS
BOTTOM_LINES = 8   # Số dòng dành cho vùng thông tin chi tiết dưới cùng

class UeberzugManager:
    """Quản lý tiến trình ueberzugpp để vẽ ảnh lên Terminal"""
    def __init__(self):
        self.process = subprocess.Popen(
            ['ueberzugpp', 'layer', '--parser', 'json'],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            text=True
        )

    def draw(self, identifier, x, y, width, height, path):
        cmd = {
            "action": "add",
            "identifier": str(identifier),
            "x": x, "y": y,
            "width": width, "height": height,
            "scaler": "fit_contain",
            "path": path
        }
        self._send(cmd)

    def clear(self, identifier):
        self._send({"action": "remove", "identifier": str(identifier)})

    def _send(self, cmd):
        if self.process.poll() is None:
            try:
                self.process.stdin.write(json.dumps(cmd) + '\n')
                self.process.stdin.flush()
            except BrokenPipeError:
                pass

    def close(self):
        if self.process.poll() is None:
            self.process.stdin.close()
            self.process.terminate()
            self.process.wait()


class YouTubeTUI:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        self.temp_dir = tempfile.TemporaryDirectory()
        self.uz = UeberzugManager()
        self.videos = []
        self.current_idx = 0
        self.is_loading = True
        self.selected_video = None
        
        # --- [SỬA ĐỔI 1]: Thêm biến quản lý trạng thái vẽ ---
        self.needs_redraw = True     # Đánh dấu khi nào cần vẽ lại UI
        self.drawn_thumbs = {}       # Lưu các ảnh đã vẽ: identifier -> path
        self.last_page = -1          # Theo dõi trang hiện tại
        
        # Cài đặt Curses
        curses.curs_set(0) # Ẩn con trỏ chuột
        curses.start_color()
        curses.use_default_colors()
        curses.init_pair(1, curses.COLOR_CYAN, -1)
        curses.init_pair(2, curses.COLOR_YELLOW, -1)
        curses.init_pair(3, curses.COLOR_MAGENTA, -1)
        curses.init_pair(4, curses.COLOR_BLACK, curses.COLOR_WHITE) # Highlight background

        # Kích hoạt luồng lấy dữ liệu
        threading.Thread(target=self.fetch_data, daemon=True).start()

    def fetch_data(self):
        cmd = [
            "yt-dlp", f"ytsearch20:{SEARCH_QUERY}",
            "--flat-playlist", "--dump-json",
            "--extractor-args", "youtube:player_client=android"
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            for line in result.stdout.strip().split('\n'):
                if not line: continue
                data = json.loads(line)
                vid_id = data.get('id')
                
                video = {
                    'id': vid_id,
                    'title': data.get('title', 'Không rõ'),
                    'channel': data.get('channel', 'Không rõ'),
                    'views': self.format_views(data.get('view_count', 0)),
                    'duration': self.format_time(data.get('duration', 0)),
                    'url': data.get('url'),
                    'img_path': os.path.join(self.temp_dir.name, f"{vid_id}.jpg"),
                    'img_ready': False
                }
                self.videos.append(video)
                self.needs_redraw = True # [SỬA ĐỔI]: Có data mới -> Cần vẽ lại
                
                # Tải thumbnail ngầm
                threading.Thread(target=self.download_thumbnail, args=(video,), daemon=True).start()
                
        except Exception as e:
            pass
        
        self.is_loading = False
        self.needs_redraw = True # [SỬA ĐỔI]: Cập nhật UI khi tải xong list

    def download_thumbnail(self, video):
        url_maxres = f"https://img.youtube.com/vi/{video['id']}/maxresdefault.jpg"
        url_hq = f"https://img.youtube.com/vi/{video['id']}/hqdefault.jpg"
        
        ret = subprocess.run(["curl", "-s", "-f", url_maxres, "-o", video['img_path']]).returncode
        if ret != 0:
            subprocess.run(["curl", "-s", "-f", url_hq, "-o", video['img_path']])
            
        video['img_ready'] = os.path.exists(video['img_path'])
        self.needs_redraw = True # [SỬA ĐỔI]: Tải xong 1 ảnh -> Cần vẽ lại để hiện ảnh

    def format_views(self, views):
        if not views: return "N/A"
        return f"{views:,}"

    def format_time(self, seconds):
        if not seconds: return "N/A"
        m, s = divmod(int(seconds), 60)
        return f"{m}:{s:02d}"

    def draw_grid(self, max_y, max_x):
        # [SỬA ĐỔI]: Dùng erase() thay clear() để giảm chớp nháy text
        self.stdscr.erase()
        
        if self.is_loading and not self.videos:
            msg = f"Đang tìm kiếm: {SEARCH_QUERY}..."
            self.stdscr.addstr(max_y // 2, (max_x - len(msg)) // 2, msg, curses.color_pair(1))
            self.stdscr.refresh()
            return

        if not self.videos:
            msg = "Không tìm thấy kết quả nào."
            self.stdscr.addstr(max_y // 2, (max_x - len(msg)) // 2, msg, curses.color_pair(2))
            self.stdscr.refresh()
            return

        grid_h = max_y - BOTTOM_LINES
        item_w = max_x // COLUMNS
        item_h = grid_h // ROWS
        
        current_page = self.current_idx // PAGE_SIZE
        start_idx = current_page * PAGE_SIZE
        end_idx = min(start_idx + PAGE_SIZE, len(self.videos))

        # --- [SỬA ĐỔI 2]: CHỈ clear Ueberzugpp khi có sự kiện CHUYỂN TRANG ---
        if self.last_page != current_page:
            for i in range(PAGE_SIZE):
                self.uz.clear(f"thumb_{i}")
            self.drawn_thumbs.clear()
            self.last_page = current_page

        for i in range(start_idx, end_idx):
            page_idx = i - start_idx
            col = page_idx % COLUMNS
            row = page_idx // COLUMNS
            
            x = col * item_w
            y = row * item_h
            w = item_w - 2  
            h = item_h - 2

            vid = self.videos[i]
            is_selected = (i == self.current_idx)
            box_attr = curses.color_pair(2) | curses.A_BOLD if is_selected else curses.A_DIM
            
            try:
                self.stdscr.attron(box_attr)
                self.stdscr.addstr(y, x, "┌" + "─"*(w) + "┐")
                for bh in range(1, h+1):
                    self.stdscr.addstr(y+bh, x, "│")
                    self.stdscr.addstr(y+bh, x+w+1, "│")
                self.stdscr.addstr(y+h+1, x, "└" + "─"*(w) + "┘")
                self.stdscr.attroff(box_attr)
                
                short_title = vid['title'][:w-2] + ".." if len(vid['title']) > w else vid['title']
                title_attr = curses.color_pair(4) if is_selected else curses.A_NORMAL
                self.stdscr.addstr(y, x+2, f" {short_title} ", title_attr)
                
            except curses.error:
                pass 

            # --- [SỬA ĐỔI 3]: CHỈ gọi lệnh draw khi ảnh chưa được vẽ trên ô tương ứng ---
            if vid['img_ready']:
                thumb_id = f"thumb_{page_idx}"
                if self.drawn_thumbs.get(thumb_id) != vid['img_path']:
                    self.uz.draw(thumb_id, x+1, y+1, w, h, vid['img_path'])
                    self.drawn_thumbs[thumb_id] = vid['img_path']

        self.draw_details(max_y, max_x)
        self.stdscr.refresh()

    def draw_details(self, max_y, max_x):
        if not self.videos: return
        vid = self.videos[self.current_idx]
        start_y = max_y - BOTTOM_LINES + 1
        
        try:
            self.stdscr.addstr(start_y - 1, 0, "═" * max_x, curses.color_pair(1))
            self.stdscr.addstr(start_y + 1, 2, f"▶ Tên: {vid['title']}", curses.color_pair(1) | curses.A_BOLD)
            self.stdscr.addstr(start_y + 2, 2, f"👤 Kênh: {vid['channel']}", curses.color_pair(2))
            self.stdscr.addstr(start_y + 3, 2, f"👁 Lượt xem: {vid['views']}")
            self.stdscr.addstr(start_y + 4, 2, f"⏱ Thời lượng: {vid['duration']}", curses.color_pair(3))
            self.stdscr.addstr(start_y + 5, 2, f"🔗 URL: {vid['url']}")
            
            controls = "[↑/↓/←/→] Điều hướng  |  [Enter] Phát nhạc  |  [Q] Thoát"
            self.stdscr.addstr(max_y - 1, max_x - len(controls) - 2, controls, curses.A_DIM)
        except curses.error:
            pass

    def run(self):
        self.stdscr.nodelay(True)
        self.stdscr.timeout(100) 
        
        while True:
            max_y, max_x = self.stdscr.getmaxyx()
            
            key = self.stdscr.getch()
            if key != -1:
                total = len(self.videos)
                # --- [SỬA ĐỔI 4]: Đánh dấu needs_redraw = True mỗi khi thao tác phím thay đổi logic ---
                if key in [ord('q'), ord('Q'), 27]: 
                    break
                elif key == curses.KEY_RIGHT and total > 0:
                    self.current_idx = min(self.current_idx + 1, total - 1)
                    self.needs_redraw = True
                elif key == curses.KEY_LEFT and total > 0:
                    self.current_idx = max(self.current_idx - 1, 0)
                    self.needs_redraw = True
                elif key == curses.KEY_DOWN and total > 0:
                    self.current_idx = min(self.current_idx + COLUMNS, total - 1)
                    self.needs_redraw = True
                elif key == curses.KEY_UP and total > 0:
                    self.current_idx = max(self.current_idx - COLUMNS, 0)
                    self.needs_redraw = True
                elif key == curses.KEY_RESIZE:
                    self.needs_redraw = True # Cập nhật lại UI khi resize terminal
                elif key in [10, 13, curses.KEY_ENTER] and total > 0:
                    self.selected_video = self.videos[self.current_idx]
                    break

            # --- [SỬA ĐỔI 5]: Chỉ gọi hàm vẽ nếu hệ thống ghi nhận có sự thay đổi state ---
            if self.needs_redraw:
                self.draw_grid(max_y, max_x)
                self.needs_redraw = False

        self.uz.close()
        self.temp_dir.cleanup()


def main(stdscr):
    app = YouTubeTUI(stdscr)
    app.run()
    return app.selected_video

if __name__ == "__main__":
    selected = curses.wrapper(main)
    
    # Xử lý phát nhạc sau khi thoát TUI
    if selected:
        print(f"\n▶️ Đang phát bài: {selected['title']}")
        subprocess.run(["mpv", "--no-video", selected['url']])
    else:
        print("\nĐã hủy chọn bài.")
