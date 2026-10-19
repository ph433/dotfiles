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
          -- Chỉ kích hoạt khi file nằm trong thư mục HRM_TruongHoangPhuong
          enabled = function()
            local buf_name = vim.api.nvim_buf_get_name(0)
            return vim.startswith(buf_name, "/home/phuong/projects/HRM_TruongHoangPhuong")
          end,
          opts = {
            prefix_min_len = 3, -- Giảm xuống 2 ký tự để test dễ ra gợi ý hơn
            context_size = 5,
            max_filesize = "1M",
            -- Chỉ truyền các cờ tùy chọn lọc file, KHÔNG truyền đường dẫn thư mục vào đây
            additional_rg_options = {
              "--type",
              "java",
            },
            -- Ép ripgrep luôn tìm kiếm bắt đầu từ thư mục src của dự án
            project_root_marker = { "src", ".git" },
          },
        },
      },
    },

    completion = {
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
