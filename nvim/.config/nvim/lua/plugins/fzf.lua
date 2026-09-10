return {
  "ibhagwan/fzf-lua",
  config = function()
    local fzf = require("fzf-lua")
    local core = require("fzf-lua.core")

    -- 1. Hook vào hàm thực thi fzf: lọc sạch mọi cờ bind/expect liên quan đến esc
    local orig_fzf_exec = core.fzf_exec
    core.fzf_exec = function(contents, opts)
      opts = opts or {}

      -- Vô hiệu hóa action esc ở tầng opts
      if opts.actions then
        opts.actions["esc"] = false
      end

      -- Nếu fzf-lua đã trót gộp flag CLI, ta lọc bỏ toàn bộ chuỗi esc:abort / expect esc
      opts.fzf_opts = opts.fzf_opts or {}
      if opts.fzf_opts["--bind"] then
        local binds = vim.split(opts.fzf_opts["--bind"], ",")
        binds = vim.tbl_filter(function(b)
          return not b:match("^esc:")
        end, binds)
        opts.fzf_opts["--bind"] = table.concat(binds, ",")
      end

      return orig_fzf_exec(contents, opts)
    end

    fzf.setup({
      keymap = {
        builtin = {
          ["<Esc>"] = false,
          ["<esc>"] = false,
        },
        fzf = {
          ["esc"] = false,
        },
      },
      actions = {
        files = { ["esc"] = false },
      },
      winopts = {
        on_create = function(e)
          local bufnr = type(e) == "table" and e.bufnr or e
          -- Gửi mã escape gốc (\x1b) thẳng vào fzf process
          vim.keymap.set("t", "<Esc>", function()
            local term_id = vim.b[bufnr].terminal_job_id
            if term_id then
              vim.api.nvim_chan_send(term_id, "\x1b")
            end
          end, { buffer = bufnr })
        end,
      },
    })
  end,
}
