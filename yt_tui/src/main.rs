use std::env;
use std::fs::{self, OpenOptions};
use std::io::{BufRead, BufReader, Write};
use std::os::unix::fs::OpenOptionsExt;
use std::process::{Command, Stdio};
use std::path::PathBuf;
use std::thread;

// Struct tự động dọn dẹp file tạm và tiến trình nền khi chương trình kết thúc
struct Cleanup {
    tmp_dir: Option<PathBuf>,
    pids: Vec<u32>,
}

impl Drop for Cleanup {
    fn drop(&mut self) {
        for pid in &self.pids {
            let _ = Command::new("kill").arg("-9").arg(pid.to_string()).output();
        }
        if let Some(ref dir) = self.tmp_dir {
            let _ = fs::remove_dir_all(dir);
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Nhập tên bài hát nữa bạn ơi! Ví dụ: yt_tui lofi chill");
        return Ok(());
    }
    let search_query = args[1..].join(" ");

    println!("🔍 Đang khởi tạo bộ xem trước...");

    // 1. Tạo thư mục tạm và FIFO
    let tmp_output = Command::new("mktemp").arg("-d").output()?;
    let tmp_dir = PathBuf::from(String::from_utf8_lossy(&tmp_output.stdout).trim());
    
    let fifo_path = tmp_dir.join("fzf-ueberzug-pipe");
    Command::new("mkfifo").arg(&fifo_path).status()?;

    // 2. Fix deadlock & Khởi động Ueberzugpp
    let script = format!(r#"
        tail -f /dev/null > "{0}" &
        p1=$!
        ueberzugpp layer --parser json --output x11 < "{0}" >/dev/null 2>&1 &
        p2=$!
        echo "$p1 $p2"
    "#, fifo_path.display());

    let u_output = Command::new("sh").arg("-c").arg(script).output()?;
    let pids: Vec<u32> = String::from_utf8_lossy(&u_output.stdout)
        .split_whitespace()
        .filter_map(|s| s.parse().ok())
        .collect();

    // Khởi tạo Guard: Nếu Rust panic hay return, nó tự động dọn dẹp
    let _cleanup = Cleanup {
        tmp_dir: Some(tmp_dir.clone()),
        pids,
    };

    // 3. Tạo Bash script cho fzf preview
    let preview_script = tmp_dir.join("preview.sh");
    let preview_content = r#"#!/usr/bin/env bash
line="$1"
url=$(echo "$line" | awk '{print $NF}')
vid_id=$(echo "$url" | sed -E 's/.*(v=|youtu\.be\/)([^&?]+).*/\2/')

tty_lines=$(tput lines < /dev/tty 2>/dev/null || echo 24)
tty_cols=$(tput cols < /dev/tty 2>/dev/null || echo 80)

if [[ -n "$vid_id" && -p "$FIFO_UEBERZUG" ]]; then
    img_path="${PREVIEW_TMP_DIR}/${vid_id}.jpg"
    current_vid_file="${PREVIEW_TMP_DIR}/current_vid"
    echo "$vid_id" > "$current_vid_file"

    TAB=$(printf '\t')
    line_data=$(grep -m 1 "^${vid_id}${TAB}" "${PREVIEW_TMP_DIR}/metadata.tsv" 2>/dev/null)
    
    t_title="Không rõ"
    t_chan="Không rõ"
    t_time="0:00"
    t_views="0"
    if [[ -n "$line_data" ]]; then
        IFS="$TAB" read -r _ t_title t_chan t_time t_views <<< "$line_data"
    fi

    prev_x=${FZF_PREVIEW_LEFT:-0}
    prev_y=${FZF_PREVIEW_TOP:-$(( tty_lines - (tty_lines * 60 / 100) ))}
    prev_w=${FZF_PREVIEW_COLUMNS:-$tty_cols}
    prev_h=${FZF_PREVIEW_LINES:-$(( (tty_lines * 60 / 100) - 1 ))}

    margin_top=2
    img_area_h=$(( prev_h * 55 / 100 ))

    ideal_w=$(( img_area_h * 35 / 10 ))
    [[ $ideal_w -gt $prev_w ]] && ideal_w=$prev_w

    img_x=$(( prev_x + (prev_w - ideal_w) / 2 ))
    img_y=$(( prev_y + margin_top ))
    img_w=$ideal_w
    img_h=$img_area_h

    for ((i=0; i < (img_area_h + margin_top); i++)); do echo ""; done
    
    print_centered() {
        local color="$1"
        local prefix="$2"
        local content="$3"
        local raw_len=$((${#prefix} + ${#content} + 1))
        local pad=$(( (prev_w - raw_len) / 2 ))
        [[ $pad -lt 0 ]] && pad=0
        printf "%${pad}s\033[%sm%s\033[0m %s\n\n" "" "$color" "$prefix" "$content"
    }

    print_centered "38;5;114" "🎵 Bài hát:" "$t_title"
    print_centered "38;5;39"  "👤 Kênh:" "$t_chan"
    print_centered "38;5;43"  "⏳ Thời lượng:" "$t_time"
    print_centered "38;5;176" "👁 Lượt xem:" "$t_views"

    draw_image() {
        if [[ "$(cat "$current_vid_file" 2>/dev/null)" == "$vid_id" ]]; then
            printf "{\"action\": \"add\", \"identifier\": \"fzf_preview\", \"x\": %d, \"y\": %d, \"width\": %d, \"height\": %d, \"scaler\": \"fit_contain\", \"path\": \"%s\"}\n" "$img_x" "$img_y" "$img_w" "$img_h" "$img_path" > "$FIFO_UEBERZUG" &
        fi
    }

    if [[ -f "$img_path" ]]; then
        draw_image
    else
        (
            curl -s -f "https://img.youtube.com/vi/${vid_id}/maxresdefault.jpg" -o "$img_path" || \
            curl -s -f "https://img.youtube.com/vi/${vid_id}/hqdefault.jpg" -o "$img_path"
            draw_image
        ) >/dev/null 2>&1 &
    fi
else
    if [[ -p "$FIFO_UEBERZUG" ]]; then
        printf "{\"action\": \"remove\", \"identifier\": \"fzf_preview\"}\n" > "$FIFO_UEBERZUG" &
    fi
fi
"#;

    let mut f = OpenOptions::new()
        .create(true)
        .write(true)
        .mode(0o755) // Cấp quyền thực thi
        .open(&preview_script)?;
    f.write_all(preview_content.as_bytes())?;

    println!("⚡ Đang truy xuất siêu tốc từ YouTube...");

    // 4. Khởi chạy Pipeline tiến trình: yt-dlp -> column -> fzf
    let mut yt_dlp = Command::new("yt-dlp")
        .args(&[
            &format!("ytsearch20:{}", search_query),
            "--flat-playlist",
            "--playlist-end", "20",
            "--dump-json",
            "--no-check-certificates",
            "--ignore-errors",
        ])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()?;

    let mut column = Command::new("column")
        .args(&["-t", "-s", "\t"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;

    let mut fzf = Command::new("fzf")
        .args(&[
            "--ansi", "--reverse",
            "--prompt=🎵 Tìm kiếm (Top 20): ",
            "--color=border:-1",
            &format!("--preview={}", preview_script.display()),
            "--preview-window=bottom:60%:border-none:noinfo",
            "--with-nth=1..-2",
            "--info=inline-right",
        ])
        .env("FIFO_UEBERZUG", &fifo_path)
        .env("PREVIEW_TMP_DIR", &tmp_dir)
        .stdin(column.stdout.take().unwrap())
        .stdout(Stdio::piped())
        .spawn()?;

    let stdout = yt_dlp.stdout.take().unwrap();
    let reader = BufReader::new(stdout);
    let mut column_stdin = column.stdin.take().unwrap();
    
    let mut meta_file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(tmp_dir.join("metadata.tsv"))?;

    // 5. Đọc Stream JSON và nạp dữ liệu vào fzf
    for (i, line) in reader.lines().enumerate() {
        let line = line?;
        let parsed: serde_json::Value = serde_json::from_str(&line).unwrap_or(serde_json::Value::Null);
        
        let title = parsed["title"].as_str().unwrap_or("Không rõ");
        let channel = parsed["channel"].as_str().or(parsed["uploader"].as_str()).unwrap_or("Không rõ");
        let duration = parsed["duration"].as_f64().unwrap_or(0.0) as u64;
        let views = parsed["view_count"].as_u64().unwrap_or(0);
        let url = parsed["url"].as_str().unwrap_or("");
        let id = parsed["id"].as_str().unwrap_or("");

        let time_str = format!("{}:{:02}", duration / 60, duration % 60);
        let views_str = format_views(views);

        writeln!(meta_file, "{}\t{}\t{}\t{}\t{}", id, title, channel, time_str, views_str)?;

        // Tải Thumbnail ngầm bằng Native Thread
        let id_clone = id.to_string();
        let tmp_clone = tmp_dir.clone();
        thread::spawn(move || {
            let path = tmp_clone.join(format!("{}.jpg", id_clone));
            let img1 = format!("https://img.youtube.com/vi/{}/maxresdefault.jpg", id_clone);
            let _ = Command::new("curl").args(&["-s", "-f", &img1, "-o"]).arg(&path).status().and_then(|st| {
                if !st.success() {
                    let img2 = format!("https://img.youtube.com/vi/{}/hqdefault.jpg", id_clone);
                    Command::new("curl").args(&["-s", "-f", &img2, "-o"]).arg(&path).status()
                } else {
                    Ok(st)
                }
            });
        });

        let trunc_title = truncate_str(title, 55, 52);
        let trunc_chan = truncate_str(channel, 20, 17);
        
        let formatted = format!(
            "\x1b[1;31m{:02}.\x1b[0m \x1b[1;32m{}\x1b[0m\t\x1b[1;33m[{}]\x1b[0m\t\x1b[1;36m{}\x1b[0m\t👁 \x1b[1;35m{}\x1b[0m\t{}\n",
            i + 1, trunc_title, trunc_chan, time_str, views_str, url
        );
        
        column_stdin.write_all(formatted.as_bytes())?;
    }

    drop(column_stdin); // Đóng luồng nạp dữ liệu để fzf/column biết đã hết

    let _ = yt_dlp.wait();
    let _ = column.wait();

    // Dọn dẹp hình ảnh ueberzugpp trước khi tắt TUI
    if fifo_path.exists() {
        let _ = Command::new("sh")
            .arg("-c")
            .arg(format!("printf '{{\"action\": \"remove\", \"identifier\": \"fzf_preview\"}}\\n' > '{}' 2>/dev/null", fifo_path.display()))
            .status();
    }

    let fzf_output = fzf.wait_with_output()?;
    let selected = String::from_utf8_lossy(&fzf_output.stdout).trim().to_string();

    // 6. Phát nhạc
    if !selected.is_empty() {
        let url = selected.split_whitespace().last().unwrap_or("");
        
        println!("▶️ Đang khởi động MPV..."); 
        Command::new("mpv")
            .args(&[
                "--no-video",
                "--ytdl-format=bestaudio",
                "--loop-file=inf",
                "--cache=yes",
                "--demuxer-max-bytes=150M",
                "--demuxer-max-back-bytes=150M",
                url
            ])
            .status()?;
    } else {
        println!("Đã hủy chọn bài.");
    }

    Ok(())
}

// Hàm format dấu phẩy cho lượt xem
fn format_views(n: u64) -> String {
    if n == 0 { return "N/A".to_string(); }
    let s = n.to_string();
    let mut result = String::new();
    for (i, c) in s.chars().rev().enumerate() {
        if i > 0 && i % 3 == 0 {
            result.push(',');
        }
        result.push(c);
    }
    result.chars().rev().collect()
}

// Hàm cắt ngắn chuỗi để không bị tràn màn hình
fn truncate_str(s: &str, limit: usize, keep: usize) -> String {
    let chars: Vec<char> = s.chars().collect();
    if chars.len() > limit {
        let mut trunc: String = chars.into_iter().take(keep).collect();
        trunc.push_str("...");
        trunc
    } else {
        s.to_string()
    }
}
