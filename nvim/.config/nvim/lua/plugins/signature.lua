return {
  "kshenoy/vim-signature",
  lazy = false, -- Nạp ngay khi mở máy để nó quản lý mark toàn thời gian
  config = function()
    -- Ông hoàn toàn có thể đổi màu sắc hiển thị của cái ghim nếu muốn
    -- Mặc định nó sẽ tự bốc màu xanh lá/hồng của theme Dracula lên nhìn rất hợp
    vim.g.SignatureMap = {
      Leader = "m",
      PlaceMark = "m.",
      ToggleMarkAtLine = "m.",
      PurgeMarksAtLine = "m-",
      DeleteMark = "dm",
      PurgeMarks = "m<Space>",
      PurgeMarkers = "m<BS>",
      GotoNextLineAlpha = "']",
      GotoPrevLineAlpha = "'[",
      GotoNextSpotAlpha = "`]",
      GotoPrevSpotAlpha = "`[",
      GotoNextLineByPos = "]`",
      GotoPrevLineByPos = "[`",
      GotoNextMarker = "]-",
      GotoPrevMarker = "[-",
      GotoNextMarkerAny = "]=",
      GotoPrevMarkerAny = "[=",
      ListLocalMarks = "m/",
      ListLocalMarkers = "m?"
    }
  end,
}
