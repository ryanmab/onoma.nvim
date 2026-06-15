local M = {}

---@param opts onoma.Config
function M.setup(opts)
	opts = vim.tbl_deep_extend('force', require('config'), opts == nil and {} or opts)

	---@type onoma.Picker[]
	local pickers = {}

	if not (type(opts.picker) == 'table') then
		table.insert(pickers, opts.picker --[[@as onoma.Picker]])
	else
		pickers = opts.picker --[[@as (onoma.Picker[])]]
	end

	for _, picker in ipairs(pickers) do
		if picker == 'telescope' then
			-- Telescope will set itself up through "telescope/_extensions/onoma.lua"
			goto continue
		end

		---@type boolean, onoma.Provider
		local ok, provider = pcall(require, 'providers.' .. picker .. '.provider')

		if not ok or provider == nil then
			error('No provider for picker: ' .. picker)
		end

		provider.setup(opts)

		::continue::
	end
end

return M
