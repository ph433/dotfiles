local M = {}
local fzf = require("fzf-lua")
local fmt = require("keyfunctions_dir.format")

local LOG_FILE = vim.fs.normalize("~/.cache/nvim_recent.log")
local LOG_DIR  = vim.fs.normalize("~/.cache/dir_recent.log")

local function extract_path(line)
  if not line then return nil end
  local p = line:match("│%s*(.+)$")
  return p or line
end

-- ==========================================
-- 1. HÀM CORE GENERIC DÙNG CHUNG TOÀN BỘ LOGIC
-- ==========================================
local function create_picker(cfg)
  local file_path = vim.fs.normalize(cfg.log_file)

  local function provider(fzf_cb)
    local f = io.open(file_path, "r")
    if f then
      local content = f:read("*a")
      f:close()

      if content and content ~= "" then
        local lines = vim.split(content, "\n", { trimempty = true })
        local seen = {}
        local count = 0
        local limit = cfg.limit or 50
        local now = os.time()

        for i = #lines, 1, -1 do
          local entry = lines[i]
          local path = entry:match("^%d+%s+(.+)$") or entry
          if not seen[path] then
            seen[path] = true
            count = count + 1
            fzf_cb(fmt.format_log_entry(entry, now, cfg.ansi_color))
            if count >= limit then break end
          end
        end
      end
    end
    fzf_cb(nil)
  end

  local tab_bind = string.format(
    [[transform:if [ -z "$FZF_QUERY" ]; then echo "change-preview(%s)+toggle-preview"; else echo 'become(echo alt-enter; printf "%%s\n" "$FZF_QUERY")'; fi]],
    cfg.cmd_cheat
  )

  fzf.fzf_exec(provider, {
    winopts = { height = 0.55, width = 0.8, border = "rounded" },
    prompt = cfg.prompt,
    header = ":: <Enter> select | <Tab> run query/help | <Ctrl-x> delete | <Ctrl-c> copy",

    fzf_opts = {
      ["--multi"] = true,
      ["--ansi"] = true,
      ["--delimiter"] = "│",
      ["--nth"] = "2..",
      ["--tiebreak"] = "index",
      ["--preview"] = cfg.cmd_cheat,
      ["--preview-window"] = "right:55%:hidden:wrap",
      ["--color"] = "hl:yellow:reverse:bold,hl+:yellow:reverse:bold,pointer:#ff79c6,marker:#ff79c6,bg+:#44475a,spinner:#ff79c6",
    },

    keymap = {
      fzf = {
        ["tab"]       = tab_bind,
        ["enter"]     = "accept",
        ["ctrl-up"]   = "half-page-up",
        ["ctrl-down"] = "half-page-down",
        ["ctrl-v"]    = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\\r\\n')\")",
        ["ctrl-c"]    = [[execute-silent(echo -n {} | awk -F '│ ' '{print $2}' | tr -d '\n' | copyq add - && copyq select 0)]],
        ["ctrl-z"]    = "clear-query",
      },
    },

    actions = {
      ["default"] = function(selected, act_opts)
        local query = (act_opts and (act_opts.last_query or act_opts.query)) or ""
        local paths = {}
        if selected and #selected > 0 then
          for _, item in ipairs(selected) do
            local p = extract_path(item)
            if p and p ~= "" then table.insert(paths, p) end
          end
        elseif query ~= "" then
          table.insert(paths, vim.trim(query))
        end
        cfg.on_select(paths)
      end,

      ["alt-enter"] = function(selected, _)
        local query = (selected and selected[1]) or ""
        local trimmed = vim.trim(query)
        if trimmed ~= "" then
          cfg.on_select({ trimmed })
        end
      end,

      ["ctrl-x"] = {
        fn = function(selected, _)
          local item = (selected and selected[1]) or ""
          local target = extract_path(item)
          if not target or target == "" then return end

          -- Copy vào Clipboard & CopyQ
          vim.fn.setreg("+", target)
          vim.fn.setreg('"', target)
          vim.fn.system({ "copyq", "add", "-" }, target)
          vim.fn.system({ "copyq", "select", "0" })

          -- Xóa entry khỏi file log tương ứng
          if vim.fn.filereadable(file_path) == 1 then
            local lines = vim.fn.readfile(file_path)
            local new_lines = {}
            for _, line in ipairs(lines) do
              local line_path = line:match("^%d+%s+(.+)$") or line
              if vim.fs.normalize(line_path) ~= vim.fs.normalize(target) then
                table.insert(new_lines, line)
              end
            end
            vim.fn.writefile(new_lines, file_path)
          end
        end,
        noclose = true,
        reload = true,
      },
    },
  })
end

-- ==========================================
-- 2. ĐỊNH NGHĨA PICKER CỤ THỂ (GỌN GÀNG)
-- ==========================================

-- Mở File gần đây
function M.fzfrecent_file()
  create_picker({
    log_file = LOG_FILE,
    prompt = "Recent Files> ",
    ansi_color = "\27[1;36m", -- Cyan
    cmd_cheat = "cat '" .. vim.fn.stdpath("cache") .. "/fzf_recent_cheat.txt'",
    on_select = function(paths)
      if not paths or #paths == 0 then return end
      for _, path in ipairs(paths) do
        vim.cmd.badd(vim.fn.fnameescape(path))
      end
      vim.cmd.edit(vim.fn.fnameescape(paths[1]))
    end,
  })
end

-- Mở / Nhảy thư mục gần đây
function M.fzfrecent_dir()
  create_picker({
    log_file = LOG_DIR,
    prompt = "Recent Dirs> ",
    ansi_color = "\27[1;33m", -- Yellow
    cmd_cheat = "cat '" .. vim.fn.stdpath("cache") .. "/fzf_recent_cheat.txt'",
    on_select = function(paths)
      if not paths or #paths == 0 then return end
      local target_dir = vim.fs.normalize(paths[1])

      -- Đổi thư mục làm việc (CWD)
      vim.cmd.cd(vim.fn.fnameescape(target_dir))

      -- Mở thư mục -> Neovim tự kích hoạt Netrw Directory Listing
      vim.cmd.edit(vim.fn.fnameescape(target_dir))
    end,
  })
end

return M
