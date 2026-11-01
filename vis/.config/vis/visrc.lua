require('vis')

-- 1. Cấu hình toàn cục và phím tắt (Chạy 1 lần khi khởi động)
vis.events.subscribe(vis.events.INIT, function()
	vis:map(vis.modes.NORMAL, '<C-v>', function()
		vis:feedkeys('"+p')
	end, 'Paste from system clipboard')
end)

-- 2. Cấu hình giao diện cửa sổ (Chạy mỗi khi mở file)
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	win.options.numbers = true
	win.options.relativenumbers = true
end)
