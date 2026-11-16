local constant = require('constant')

local M = {}

M.check = function()
	vim.health.start('Bridge')

	local ok, bridge = pcall(require('bridge.utils').load_bridge)

	if ok then
		vim.health.ok('Bridge loaded successfully.')
	else
		vim.health.error('Bridge could not be loaded: ' .. bridge)
	end

	vim.health.start('Pickers')

	for _, picker in ipairs(constant.PICKERS) do
		---@type boolean, onoma.Provider|nil
		local ok, provider = pcall(require, 'providers.' .. picker .. '.provider')

		if not ok or provider == nil then
			vim.health.error('Picker not found: ' .. provider)

			goto continue
		end

		pcall(provider.health)

		::continue::
	end
end

return M
