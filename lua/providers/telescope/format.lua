local M = {}

local entry_display = require('telescope.pickers.entry_display')
local make_entry = require('telescope.make_entry')
local utils = require('telescope.utils')

-- Symbol icons inspired heavily by Snacks.nvim.
--
-- See: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/config/defaults.lua
M.icons = {
	Array = ' ',
	Boolean = '󰨙 ',
	Class = ' ',
	Color = ' ',
	Control = ' ',
	Collapsed = ' ',
	Constant = '󰏿 ',
	Constructor = ' ',
	Copilot = ' ',
	Enum = ' ',
	EnumMember = ' ',
	Event = ' ',
	Field = ' ',
	File = ' ',
	Folder = ' ',
	Function = '󰊕 ',
	Interface = ' ',
	Key = ' ',
	Keyword = ' ',
	Method = '󰊕 ',
	Module = ' ',
	Namespace = '󰦮 ',
	Null = ' ',
	Number = '󰎠 ',
	Object = ' ',
	Operator = ' ',
	Package = ' ',
	Property = ' ',
	Reference = ' ',
	Snippet = '󱄽 ',
	String = ' ',
	Struct = '󰆼 ',
	Text = ' ',
	TypeParameter = ' ',
	Unit = ' ',
	Unknown = ' ',
	Value = ' ',
	Variable = '󰀫 ',
}

M.substr_highlighter = function()
	local make_display = function(prompt, display)
		-- If smart case is enabled, and the prompt contains uppercase characters
		-- highlight case sensitively, otherwise do a case insensitive match.
		if vim.o.smartcase then
			local has_upper_case = not not prompt:match('%u')
			return has_upper_case and display or display:lower()
		end

		return display:lower()
	end

	return function(_, prompt, display)
		local highlights = {}
		display = make_display(prompt, display)

		local search_terms = utils.max_split(prompt, '%s')
		local hl_start, hl_end

		for _, word in pairs(search_terms) do
			hl_start, hl_end = display:find(word, 1, true)
			if hl_start then
				table.insert(highlights, { start = hl_start, finish = hl_end })
			end
		end

		return highlights
	end
end

M.lsp_symbol = function()
	local displayer = entry_display.create({
		separator = ' ',
		items = {
			{ remaining = true },
			{ remaining = true },
			{ remaining = true },
			{ remaining = true },
		},
	})

	local make_display = function(entry)
		local _, icon_highlight_group, icon = utils.transform_devicons(entry.path, entry.path, false)
		local path, path_style = utils.transform_path({}, entry.path)

		-- I.e. `TelescopeResultsClass`. Worth noting that Telescope doesn't model all the
		-- symbol kinds which Onoma does, so there will likely be highlight groups which
		-- are not present by default.
		local kind_highlight_group = 'TelescopeResults' .. entry.symbol_kind

		return displayer({
			{ icon, icon_highlight_group },
			{
				M.icons[entry.symbol_kind] or M.icons['Unknown'],
				kind_highlight_group,
			},
			{
				entry.symbol_name .. ' ',
				kind_highlight_group,
			},
			{
				path,
				'TelescopeResultsLineNr',
				function()
					return path_style
				end,
			},
		})
	end

	return function(entry)
		entry.display = make_display
		return make_entry.set_default_entry_mt(entry)
	end
end

return M
