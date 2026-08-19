-- ~/.config/nvim/lua/plugins/blink.lua
return {
  "saghen/blink.cmp",
  dependencies = "rafamadriz/friendly-snippets",
  version = "v0.*",
  opts = {
    keymap = { preset = "default" },
    sources = {
      -- Tự động fallback: Nếu không có LSP, nó vẫn gợi ý mượt mà bằng buffer/path/snippets
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
