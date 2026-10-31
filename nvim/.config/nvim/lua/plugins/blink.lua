return {
  "saghen/blink.cmp",
  dependencies = {
    "rafamadriz/friendly-snippets",
    "mikavilpas/blink-ripgrep.nvim",
  },
  version = "v0.*",
  opts = {
    sources = {
      default = { "ripgrep", "buffer", "snippets", "path" },
      providers = {
        ripgrep = {
          module = "blink-ripgrep",
          name = "Ripgrep",
          -- Tăng độ ưu tiên để kết quả ripgrep nổi lên ngay khi có
          score_offset = 3,
          -- Cho phép kích hoạt lại ngay khi gõ từ 2 ký tự sau dấu chấm
          min_keyword_length = 2,
          
          enabled = function()
            local buf_name = vim.api.nvim_buf_get_name(0)
            return vim.startswith(buf_name, "/home/phuong/projects/HRM_TruongHoangPhuong")
          end,

          opts = {
            -- Giảm prefix_min_len để ripgrep tìm kiếm sớm hơn (ngay từ 2 ký tự)
            prefix_min_len = 2,
            context_size = 5,
            max_filesize = "1M",
            additional_rg_options = {
              "--type",
              "java",
            },
            project_root_marker = { "src", ".git" },
            
            -- Tùy chỉnh tách prefix: đảm bảo sau dấu chấm (.) ripgrep luôn lấy đúng từ đang gõ
            get_prefix = function(context)
              local line = context.line:sub(1, context.cursor[2])
              return line:match("[%w_]+$") or ""
            end,
          },
        },
      },
    },

    completion = {
      -- Giảm thời gian chờ debounce để kết quả async trả về nhanh hơn
      trigger = {
        prefetch_on_insert = true,
        show_on_keyword = true,
        show_on_trigger_character = true,
      },
      list = {
        selection = {
          preselect = true,
          auto_insert = false,
        },
      },
    },

    keymap = {
      preset = "default",
      ["<Down>"] = { "select_next", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
    },
  },
}
