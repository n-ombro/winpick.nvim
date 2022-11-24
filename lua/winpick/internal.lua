local api = vim.api

local alphabet = {}
for byte = string.byte("a"), string.byte("z") do
	table.insert(alphabet, string.char(byte))
end

local M = {}

--- Builds the default options.
--- @return table: The defaults.
function M.defaults()
	return {
		filter = nil,
		chars = nil,
	}
end

--- Maps a table index to an ASCII character starting from A (1 is A, 2 is B, and so on).
--- @param idx integer: Index of a table.
--- @return string: The respective ASCII character.
function M.format_index(idx)
	return string.char(idx + 64)
end

--- Returns the list of labels that will sequentially be used for visual cues.
--- @param custom_chars table: List of characters that will serve as labels.
--- @return table: Alphabet containing user-provided characters plus a complementary alphabet.
function M.resolve_chars(custom_chars)
	if vim.tbl_isempty(custom_chars) then
		return alphabet
	end

	local chars = {}
	local added = {}

	for _, charlist in ipairs({ custom_chars, alphabet }) do
		for _, char in ipairs(charlist) do
			local val = char:upper()

			if not added[val] then
				added[val] = true
				table.insert(chars, val)
			end
		end
	end

	return chars
end

--- Shows visual cues for each window.
--- @param targets table: Map of labels and their respective window objects.
--- @return table: List of visual cues that were opened.
function M.show_cues(targets)

	-- Reset view.
	local cues = {}
	for label, win in pairs(targets) do
		local bufnr = api.nvim_create_buf(false, true)

    local text = string.format(' %s ', label)
    local col = (api.nvim_win_get_width(win.id) - text:len()) / 2
    local row = (api.nvim_win_get_height(win.id) - 3) / 2

		api.nvim_buf_set_lines(bufnr, 0, 0, false, {text})

    local borderchars = {'╭', '─', '╮', '│', '╯', '─', '╰', '│'}

		local cue_winid = api.nvim_open_win(bufnr, false, {
			relative = "win",
			win = win.id,
			width = text:len(),
			height = 1,
			col = col,
			row = row,
      anchor = 'NE',
			focusable = false,
			style = "minimal",
			border = borderchars,
		})

		pcall(api.nvim_buf_set_option, cue_winid, "buftype", "nofile")
		pcall(api.nvim_buf_set_option, cue_winid, "filetype", "winpick")

		table.insert(cues, cue_winid)
	end

	return cues
end

--- Closes all windows for visual cues.
function M.hide_cues(cues)
	for _, win in pairs(cues) do
		-- We use pcall here because we dont' want to throw an error just
		-- because we couldn't close a window that was probably already closed!
		pcall(api.nvim_win_close, win, true)
	end
end

return M
