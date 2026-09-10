return {
  "ibhagwan/fzf-lua",
  config = function()
    local fzf = require("fzf-lua")
    local core = require("fzf-lua.core")
    local config = require("fzf-lua.config")

    -- 1. Hook vào TermOpen và dùng vim.schedule để đợi filetype được set
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*",
      callback = function(args)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].filetype == "fzf" then
            pcall(vim.keymap.del, "t", "<Esc>", { buffer = args.buf })
            pcall(vim.keymap.del, "t", "<esc>", { buffer = args.buf })

            vim.keymap.set("t", "<Esc>", function()
              local term_id = vim.b[args.buf].terminal_job_id
              if term_id then
                vim.api.nvim_chan_send(term_id, "\x1b")
              end
            end, { buffer = args.buf, nowait = true })
          end
        end)
      end,
    })

    -- 2. Hook vào normalize_opts - nơi fzf-lua thực sự sinh ra cờ CLI và gom bind/expect
    local orig_normalize = config.normalize_opts
    config.normalize_opts = function(opts, defaults)
      opts = orig_normalize(opts, defaults) or {}

      -- Triệt hạ esc trong actions và expect
      if opts.actions then
        opts.actions["esc"] = false
      end

      -- Xóa triệt để cờ CLI do normalize sinh ra
      local function purge_esc(opt_key, prefix)
        if opts[opt_key] then
          local parts = vim.split(opts[opt_key], ",")
          parts = vim.tbl_filter(function(x)
            return not x:lower():match("^" .. prefix)
          end, parts)
          opts[opt_key] = #parts > 0 and table.concat(parts, ",") or nil
        end
      end

      -- Lọc sạch cờ expect và bind
      purge_esc("--expect", "esc$")
      purge_esc("--bind", "esc:")

      if opts.fzf_opts then
        if opts.fzf_opts["--expect"] then
          local ex = vim.split(opts.fzf_opts["--expect"], ",")
          ex = vim.tbl_filter(function(x) return x:lower() ~= "esc" end, ex)
          opts.fzf_opts["--expect"] = #ex > 0 and table.concat(ex, ",") or nil
        end
        if opts.fzf_opts["--bind"] then
          local bi = vim.split(opts.fzf_opts["--bind"], ",")
          bi = vim.tbl_filter(function(x) return not x:lower():match("^esc:") end, bi)
          opts.fzf_opts["--bind"] = #bi > 0 and table.concat(bi, ",") or nil
        end
      end

      return opts
    end

    fzf.setup({
      keymap = {
        builtin = { ["<Esc>"] = false, ["<esc>"] = false },
        fzf = { ["esc"] = false },
      },
      actions = { ["esc"] = false },
    })
  end,
}
