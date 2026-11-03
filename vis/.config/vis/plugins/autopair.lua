require('vis')

local brackets = {
	["("] = "()",
	["{"] = "{}",
	["["] = "[]",
	-- ["<"] = "<>",
	["'"] = "''",
	['"'] = '""',
	['`'] = '``',
};

local closed = {
	[")"] = "",
	["}"] = "",
	["]"] = "",
	[">"] = "",
	["'"] = "",
	['"'] = "",
	["`"] = "",
};

local remove = {
	["()"] = "",
	["{}"] = "",
	["[]"] = "",
	["<>"] = "",
	["''"] = "",
	['""'] = "",
	['``'] = "",
};

function is_bracket_or_empty(char)
	return 	char == ' ' or
		char == '\n' or
		brackets[char] ~= nil or
		closed[char] ~= nil
end

vis.events.subscribe(vis.events.INPUT, function(key)
	local file = vis.win.file
	local cursor = vis.win.selection.pos
	local next = file:content(cursor, 1)
	-- closed bracket already exists, skip
	if key == next and closed[next] ~= nil then
		vis:feedkeys('<Right>')
		return true
	end

	local result = brackets[key]
	if result ~= nil and is_bracket_or_empty(next) then
		vis:insert(result)
		vis:feedkeys('<Left>')
		return true
	end
end)

vis:map(vis.modes.INSERT, "<Backspace>", function(keys)
	local cursor = vis.win.selection.pos

	if cursor == 0 then
		return 1
	end

	local file = vis.win.file
	local prev = file:content(cursor-1, 2)

	-- Workaround until https://github.com/martanne/vis/issues/739 is solved
	vis:feedkeys("<Left>")
	-- Check if whole bracket pair is to be removed
	if prev ~= nil then
		local result = remove[prev]
		if result ~= nil then
			vis:feedkeys("<Delete>")
		end
	end

	vis:feedkeys("<Delete>")
	return 1
end, "Removes the previous character (and closed brackets, if empty)")

vis:map(vis.modes.INSERT, '<Enter>', function()
	local file = vis.win.file
	local cursor = vis.win.selection.pos
	-- Lấy 2 ký tự: Dấu mở ngoặc (bên trái) và dấu đóng ngoặc (ngay tại con trỏ)
	local prev = file:content(cursor - 1, 2)

	-- Danh sách các cặp ngoặc
	local brackets = { ["()"] = 1, ["{}"] = 1, ["[]"] = 1 }

	if prev ~= nil and brackets[prev] then
		-- Nếu 2 ký tự trước là cặp ngoặc (ví dụ "{}")
		local close_char = prev:sub(2, 2) -- Lấy ký tự thứ 2 (dấu đóng)
		
		-- 1. Chèn xuống dòng và dấu đóng ngoặc tương ứng
		vis:insert("\n\n" .. close_char)
		
		-- 2. Di chuyển con trỏ lên dòng giữa
		vis:feedkeys('<Up><End>')
		
		-- 3. Thụt lề (Tab)
		vis:feedkeys('<Tab>')
		return true
	else
		-- Nếu không phải cặp ngoặc, gọi trực tiếp hành động gốc của phím Enter
		-- TUYỆT ĐỐI KHÔNG DÙNG vis:feedkeys('<Enter>') Ở ĐÂY ĐỂ TRÁNH LẶP VÔ HẠN
		vis:feedkeys('<vis-insert-newline>')
		return true
	end
end, "Smart Enter (xuống dòng + thụt lề nếu trong ngoặc)")

