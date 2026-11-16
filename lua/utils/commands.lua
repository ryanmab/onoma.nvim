local M = {}

---@param resolver onoma.Resolver|nil
---@param watcher onoma.Watcher|nil
function M.setup_user_commands(resolver, watcher)
	vim.api.nvim_create_user_command('Onoma', function(opts)
		local command = opts.fargs[1]

		if command == 'update' then
			vim.schedule(function()
				M.build():run()
			end)
		elseif command == 'run_full_index' then
			if watcher == nil then
				error('Cannot run full index as watcher has not been initialised')
			end

			local ok, err = pcall(watcher.run_full_index, watcher)

			if not ok then
				error('Failed to run full index: ' .. err)
			end

			vim.notify('Full index has been started.')
		elseif command == 'health' then
			vim.cmd('checkhealth onoma')
		else
			error(string.format('"%s" is not a valid command', command), vim.log.levels.ERROR)
		end
	end, { nargs = 1 })
end

return M
