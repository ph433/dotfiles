local M = {}

M.fzf_command_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  fzf.command_history({
    winopts = { height = 0.4, width = 0.7, border = "rounded" },
    prompt = "Cmd History> ",
    keymap = {
      fzf = {
        ["ctrl-z"]  = "transform-query(echo -n {})",
        ["ctrl-up"] = "half-page-up",
        ["ctrl-down"] = "half-page-down",
        -- Lấy clipboard hiện tại từ CopyQ và nối vào query đang nhập
        ["ctrl-v"] = "transform-query(printf '%s%s' {q} \"$(copyq clipboard | tr -d '\\r\\n')\")",
        ["ctrl-c"] = "execute-silent(echo -n {} | copyq add - && copyq select 0)",
      },
    },
    actions = {
      -- 1. Khi bấm Tab: chạy query đang gõ và cập nhật lịch sử
      ["tab"] = function(_, opts)
        local query = opts.last_query
        if query and #query > 0 then
          vim.fn.histadd("cmd", query)
          vim.cmd(query)
        end
      end,

      -- 2. Khi bấm Enter: ưu tiên dòng đang chọn, nếu không khớp thì lấy query đang gõ
      ["default"] = function(selected, opts)
        local cmd = (selected and selected[1]) or (opts and opts.last_query)
        if cmd and #cmd > 0 then
          vim.fn.histadd("cmd", cmd)
          vim.cmd(cmd)
        end
      end,
    },
  })
end

return M
