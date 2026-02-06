local M = {}

---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.filename(item, picker)
	local ret = {}
	if not item.file then
		return ret
	end
	local path = Snacks.picker.util.path(item) or item.file

	local base_hl = item.dir and 'SnacksPickerDirectory' or 'SnacksPickerFile'
	local function is(prop)
		local it = item
		while it do
			if it[prop] then
				return true
			end
			it = it.parent
		end
	end

	if is('ignored') then
		base_hl = 'SnacksPickerPathIgnored'
	elseif item.filename_hl then
		base_hl = item.filename_hl
	elseif is('hidden') then
		base_hl = 'SnacksPickerPathHidden'
	end
	local dir_hl = 'SnacksPickerDir'

	ret[#ret + 1] = {
		'',
		resolve = function(max_width)
			local truncpath = Snacks.picker.util.truncpath(
				path,
				math.max(max_width, picker.opts.formatters.file.min_width or 20),
				{ cwd = picker:cwd(), kind = picker.opts.formatters.file.truncate }
			)
			local dir, base = truncpath:match('^(.*)/(.+)$')

			local resolved = {} ---@type snacks.picker.Highlight[]
			if base and dir then
				resolved[#resolved + 1] = { dir .. '/' .. base, dir_hl, field = 'file' }
			else
				resolved[#resolved + 1] = { truncpath, base_hl, field = 'file' }
			end

			return resolved
		end,
	}

	ret[#ret + 1] = { ' ' }
	if item.type == 'link' then
		local real = uv.fs_realpath(item.file)
		local broken = not real
		real = real or uv.fs_readlink(item.file)
		if real then
			ret[#ret + 1] = { '-> ', 'SnacksPickerDelim' }
			ret[#ret + 1] =
				{ Snacks.picker.util.truncpath(real, 20), broken and 'SnacksPickerLinkBroken' or 'SnacksPickerLink' }
			ret[#ret + 1] = { ' ' }
		end
	end

	return ret
end

---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.lsp_symbol(item, picker)
	local ret = {}

	local kind = item.lsp_kind or item.kind or 'Unknown' ---@type string
	kind = picker.opts.icons.kinds[kind] and kind or 'Unknown'

	local kind_hl = 'SnacksPickerIcon' .. kind

	if picker.opts.icons.files.enabled ~= false then
		local path = Snacks.picker.util.path(item) or item.file

		local name, cat = path, (item.dir and 'directory' or 'file')
		if item.buf and vim.api.nvim_buf_is_loaded(item.buf) and vim.bo[item.buf].buftype ~= '' then
			name = vim.bo[item.buf].filetype
			cat = 'filetype'
		end
		local icon, hl = Snacks.util.icon(name, cat, {
			fallback = picker.opts.icons.files,
		})
		if item.buftype == 'terminal' then
			icon, hl = ' ', 'Special'
		end
		if item.dir and item.open then
			icon = picker.opts.icons.files.dir_open
		end
		icon = Snacks.picker.util.align(icon, picker.opts.formatters.file.icon_width or 2)
		ret[#ret + 1] = { icon, hl }
	end

	ret[#ret + 1] = { picker.opts.icons.kinds[kind], kind_hl }
	ret[#ret + 1] = { ' ' }

	local name = vim.trim(item.name:gsub('\r?\n', ' '))
	name = name == '' and item.detail or name
	Snacks.picker.highlight.format(item, name, ret)

	-- Show the filename (truncated) next to the Symbol
	ret[#ret + 1] = { '  ' }
	vim.list_extend(ret, M.filename(item, picker))

	return ret
end

return M
