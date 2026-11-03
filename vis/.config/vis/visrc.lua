require('vis')
require('plugins/autopair')
-- 1. Cấu hình toàn cục và phím tắt (Chạy 1 lần khi khởi động)
vis.events.subscribe(vis.events.INIT, function()
	vis:map(vis.modes.NORMAL, '<C-v>', function()
		vis:feedkeys('"+p')
	end, 'Paste from system clipboard')
	vis:map(vis.modes.VISUAL, '<C-v>', function()
		vis:feedkeys('"+p')
	end, 'Paste from system clipboard')
	vis:map(vis.modes.VISUAL, '<C-c>', function()
		vis:feedkeys('"+y')
	end, 'My Copy to system clipboard')
	
	-- Chế độ NORMAL
	vis:map(vis.modes.NORMAL, '<Backspace>', 'X')
	vis:map(vis.modes.NORMAL, '<Delete>', 'x')
	-- Chế độ VISUAL
	vis:map(vis.modes.VISUAL, '<Backspace>', 'd')
	vis:map(vis.modes.VISUAL, '<Delete>', 'x')
	vis:map(vis.modes.NORMAL, '<Enter>', '<vis-insert-newline>', 'Insert newline')
	vis:map(vis.modes.NORMAL, ' ', function()
		vis:insert(' ')
	end, 'Chèn dấu cách')
end)

-- 2. Cấu hình giao diện cửa sổ (Chạy mỗi khi mở file)
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	win.options.numbers = true
	win.options.relativenumbers = true
	win.options.showtabs = true
	vis:command('set autoindent')
	vis:command('set tabwidth 4')
end)


-- Tạo một lệnh mới tên là ":run"
vis:command_register("run", function(argv, force, win, selection, range)
    local filepath = vis.win.file.path
    if filepath then
        local success, err = pcall(dofile, filepath)
        if not success then
            vis:info("Lỗi: " .. tostring(err))
        end
    else
        vis:info("File chưa được lưu!")
    end
    return true
end, "Chạy file Lua hiện tại")

-- Test sự kiện WIN_CLOSE
vis.events.subscribe(vis.events.WIN_CLOSE, function(win)
    local f = io.open("/tmp/log.txt", "a") -- Mở file ở chế độ ghi nối (append)
    if f then
        f:write("hello\n")
        f:close()
    end
end)
