return {
  "saghen/blink.cmp",
  dependencies = "rafamadriz/friendly-snippets",
  version = "v0.*",
  opts = {
    -- Thêm phần cấu hình completion này
    completion = {
      list = {
        selection = {
          preselect = true,
          auto_insert = false, -- QUAN TRỌNG: Tắt tự động điền thử khi cuộn menu
        }
      }
    },

    keymap = {
      preset = "default",

      ["<Down>"] = { "select_next", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },

      -- Phím chốt từ (Enter)
      ["<CR>"] = { "accept", "fallback" },
    },
  },
}
