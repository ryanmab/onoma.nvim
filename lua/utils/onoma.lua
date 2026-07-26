local M = {}

---@param directories string[]
---@return onoma.Resolver
function M.new_resolver(directories)
	local utils = require('bridge.utils')
	local log = require('utils.log')

	local ok, onoma = pcall(utils.load_bridge)
	if not ok or onoma == nil then
		error('Onoma did not load correctly: ' .. onoma)
	end

	local ok, resolver = pcall(onoma.get_resolver, directories)
	if not ok then
		error('Failed to initialise resolver for directories: ' .. table.concat(directories, ', '))
	end

	log.debug('Resolver initialised for: ' .. table.concat(directories, ', '))

	return resolver
end

---@param directories string[]
---@return onoma.Watcher
function M.new_watcher(directories)
	local utils = require('bridge.utils')
	local log = require('utils.log')

	local ok, onoma = pcall(utils.load_bridge)
	if not ok or onoma == nil then
		error('Onoma did not load correctly: ' .. onoma)
	end

	local ok, watcher = pcall(onoma.get_watcher, directories)
	if not ok then
		error('Failed to initialise watcher for directories: ' .. table.concat(directories, ', '))
	end

	log.debug('Watcher initialised for: ' .. table.concat(directories, ', '))

	vim.api.nvim_create_autocmd('VimLeavePre', {
		group = vim.api.nvim_create_augroup('onoma_watcher', { clear = true }),
		callback = function()
			log.trace('Vim is exiting')

			if watcher then
				local ok, err = pcall(watcher.stop, watcher)

				if not ok then
					log.error('Failed to stop watcher: ' .. tostring(err))
					return
				end

				log.trace('Watcher has been cleaned up')

				-- Since Vim is closing, we want to flush any buffered logs
				log.flush()
			end
		end,
	})

	return watcher
end

return M
