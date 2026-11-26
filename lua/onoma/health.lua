local constant = require('constant')

local M = {}

M.check = function()
	vim.health.start('Bridge')
	local utils = require('bridge.utils')
	local git = require('bridge.git')

	local ok, _ = pcall(utils.load_bridge)

	if ok then
		local _, library_path = pcall(utils.get_library_path)

		vim.health.ok('Bridge loaded successfully: `' .. library_path .. '`')

		local downloaded_tag = git.get_downloaded_release_tag()

		if downloaded_tag ~= nil then
			vim.health.ok('Version: `' .. downloaded_tag .. '`')
		else
			vim.health.warn('Version: `(not set)`')
		end
	else
		local _, library_path = pcall(utils.get_library_path)

		vim.health.error('Bridge could not be loaded: `' .. library_path .. '`')
	end

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
