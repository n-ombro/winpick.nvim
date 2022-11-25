package.loaded["winpick"] = nil
package.loaded["winpick.internal"] = nil

local internal = require("winpick.internal")

local api = vim.api

local ESC_CODE = 27

local defaults = internal.defaults()

local M = {}

--- Prompts for a window to be selected. A callback is used for handling the action. The default
--- action is to focus the selected window. The argument passed to the callback is a window ID if a
--- window is selected or nil if it the selection is aborted.
--- @param opts table | nil: Optional options that may override global options.
--- @return number | nil, number | nil: Selected window table containing ID and its corresponding buffer ID.
function M.select(opts)
	opts = vim.tbl_deep_extend("force", defaults, opts or {})

	local wins = api.nvim_tabpage_list_wins(0)
	wins = vim.tbl_map(function(winid)
		return {
			id = winid,
			bufnr = api.nvim_win_get_buf(winid),
		}
	end, wins)

	-- Filter out some buffers according to configuration.
	local eligible_wins = vim.tbl_filter(function(win)
		if opts.filter then
			return opts.filter(win.id, win.bufnr)
		end

		return true
	end, wins)

	if #eligible_wins == 0 then
		eligible_wins = wins
	end

	if #eligible_wins == 1 then
		local win = eligible_wins[1]
		return win.id, win.bufnr
	end

  if #eligible_wins == 2 then
    vim.cmd("mode") -- clear cmdline once

    local ok, choice = pcall(vim.fn.getchar) -- Ctrl-C returns an error

    vim.cmd("mode") -- clear cmdline again to remove pick-up message

    local is_ctrl_c = not ok
    local is_esc = choice == ESC_CODE

    if is_ctrl_c or is_esc then
      return nil, nil
    end

    local char = string.char(choice)
    api.nvim_command('wincmd '..char)
    return nil, nil
  end

	local targets = {}
	local chars = internal.resolve_chars(opts.chars or {})
	local total_chars = #chars

	if #eligible_wins > total_chars then
		vim.notify(
			"[winpick.nvim] The number of eligible windows is greater than the number of label characters, some windows will never be picked",
			vim.log.levels.WARN
		)
	end

	for idx, win in ipairs(eligible_wins) do
		local next_char = chars[idx % (total_chars + 1)]
		targets[next_char] = win
	end

	local cues = internal.show_cues(targets)

	vim.cmd("mode") -- clear cmdline once

	local ok, choice = pcall(vim.fn.getchar) -- Ctrl-C returns an error

	vim.cmd("mode") -- clear cmdline again to remove pick-up message
	internal.hide_cues(cues)

	local is_ctrl_c = not ok
	local is_esc = choice == ESC_CODE

	if is_ctrl_c or is_esc then
		return nil, nil
	end

  local char = string.char(choice)
  if not string.find('abcdefgABCDEFG', char) then
    api.nvim_command('wincmd '..char)
		return nil, nil
  end

	local win = targets[char]

	if win then
		return win.id, win.bufnr
	end

	return nil, nil
end

--- Sets up the plug-in by overriding default options.
--- @param opts table: Options to be globally overridden.
function M.setup(opts)
	defaults = vim.tbl_deep_extend("force", defaults, opts or {})
end

--- Default values, for reusability. Read-only, errors if modified.
M.defaults = setmetatable({}, {
	__index = internal.defaults(),
	__newindex = function()
		error("defaults are read-only")
	end,
})

return M
