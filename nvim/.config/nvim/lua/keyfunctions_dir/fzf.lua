local M = {}

M.fzf_command_history = function()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return end

  fzf.command_history({
    winopts = { height = 0.4, width = 0.7, border = "rounded" },
    prompt = "Cmd History> ",
    keymap = {
      fzf = {
        ["right"]  = "transform-query(echo -n {})",
        ["ctrl-u"] = "half-page-up",
        ["ctrl-d"] = "half-page-down",
      },
    },
    actions = {
      -- 1. Khi bấm Tab: chạy query đang gõ và cập nhật lịch sử
      ["tab"] = function(_, opts)
        local query = opts.last_query
        if query and #query > 0 then
          vim.fn.histadd("cmd", query) -- Thêm trực tiếp vào command history của Vim
          vim.cmd(query)               -- Thực thi lệnh
        end
      end,
      
      -- 2. Khi bấm Enter: chạy dòng đang chọn và đảm bảo đưa lên đầu lịch sử
      ["default"] = function(selected)
        if selected and selected[1] then
          vim.fn.histadd("cmd", selected[1])
          vim.cmd(selected[1])
        end
      end,
    },
  })
end

return M
