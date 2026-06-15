local M = {}

---@param directories string[]
---@return onoma.Resolver
function M.new_resolver(directories)
	local utils = require('bridge.utils')
	local log = require('utils.log')

	local ok, onoma = pcall(utils.load_bridge)
	if not ok or onoma == nil then
		vim.notify_once('Onoma did not load correctly: ' .. onoma, vim.log.levels.ERROR)
		error()
	end

	local resolver = onoma.get_resolver(directories)
	log.debug('Resolver created at: ' .. os.date('%Y-%m-%d %H:%M:%S'))

	return resolver
end

---@param directories string[]
---@return onoma.Watcher
function M.new_watcher(directories)
	local utils = require('bridge.utils')
	local log = require('utils.log')

	local ok, onoma = pcall(utils.load_bridge)
	if not ok or onoma == nil then
		vim.notify_once('Onoma did not load correctly: ' .. onoma, vim.log.levels.ERROR)
		error()
	end

	local watcher = onoma.get_watcher(directories)

	if not watcher then
		log.error('Failed to create watcher for directories: ' .. table.concat(directories, ', '))
		error()
	end

	log.debug('Watcher created at: ' .. os.date('%Y-%m-%d %H:%M:%S'))

	vim.api.nvim_create_autocmd('VimLeavePre', {
		group = vim.api.nvim_create_augroup('onoma_watcher', { clear = true }),
		callback = function()
			log.trace('Vim is exiting')

			if watcher then
				local ok, err = pcall(watcher.stop_blocking, watcher)

				if not ok then
					log.error('Failed to stop watcher: ' .. tostring(err))
					return
				end

				log.debug('Watcher has been cleaned up')
			end
		end,
	})

	return watcher
end

return M
