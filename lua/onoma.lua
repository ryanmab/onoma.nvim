local commands = require('utils.commands')
local log = require('utils.log')

local M = {}

-- Initialise the resolver and watcher, ready for providers to hook into.
--
-- This is done asynchronously, so that the resolver and watcher can be initialised in the background
-- without blocking the main thread.
--
---@param directories string[]
---@return { resolver: onoma.Resolver, watcher: onoma.Watcher }
local function initialise_onoma(directories)
	local Async = require('utils.async')
	local onoma = require('utils.onoma')

	log.info('Initialising integration for: ' .. table.concat(directories, ', '))

	---@type onoma.Resolver, onoma.Watcher
	local resolver, watcher = unpack(Async(function()
		---@type boolean, onoma.Resolver
		local ok, resolver = pcall(onoma.new_resolver, directories)
		if not ok then
			error('Failed to create resolver: ' .. resolver)
		end

		---@type boolean, onoma.Watcher
		local ok, watcher = pcall(onoma.new_watcher, directories)
		if not ok then
			error('Failed to create watcher: ' .. watcher)
		end

		return {
			resolver,
			watcher,
		}
	end):await())

	Async(function()
		local ok, err = pcall(watcher.start, watcher)

		if not ok then
			error('Failed to start watcher: ' .. err)
		end

		local ok, err = pcall(watcher.run_full_index, watcher)

		if not ok then
			error('Failed to run full index: ' .. err)
		end
	end):run()

	return {
		resolver,
		watcher,
	}
end

---@param opts onoma.Config
function M.setup(opts)
	opts = vim.tbl_deep_extend('force', require('config'), opts == nil and {} or opts)

	local ok, bridge = pcall(require('bridge.utils').load_bridge)

	if not ok then
		-- We couldn't start setup as the bridge failed to load.
		--
		-- NB: we can't even use the logging utils here as they rely
		-- on the bridge being loaded.
		vim.notify('Setup failed: ' .. bridge, vim.log.levels.ERROR)
		commands.setup_user_commands()
		return
	end

	local onoma = require('utils.onoma')
	onoma.set_debug_mode(opts.debug)

	---@type onoma.Picker[]
	local pickers = {}

	if not (type(opts.picker) == 'table') then
		table.insert(pickers, opts.picker --[[@as onoma.Picker]])
	else
		pickers = opts.picker --[[@as (onoma.Picker[])]]
	end

	if #pickers == 0 then
		log.warn('No pickers specified, nothing to setup')
		commands.setup_user_commands()

		return
	end

	local project_directory = { vim.fn.getcwd() }
	local ok, init = pcall(initialise_onoma, project_directory)

	if not ok then
		log.error('Failed to initialise onoma: ' .. init)
		commands.setup_user_commands()

		return
	end

	local resolver, watcher = unpack(init)
	commands.setup_user_commands(resolver, watcher)

	for _, picker in ipairs(pickers) do
		---@type boolean, onoma.Provider
		local ok, provider = pcall(require, 'providers.' .. picker .. '.provider')

		if not ok or provider == nil then
			vim.notify('No provider for picker: ' .. picker, vim.log.levels.WARN)

			goto continue
		end

		local ok, err = pcall(provider.setup, resolver, watcher, opts)

		if not ok then
			vim.notify('Failed to setup picker (' .. picker .. '): ' .. err, vim.log.levels.ERROR)

			goto continue
		end

		::continue::
	end
end

function M.build()
	local Async = require('utils.async')

	return Async(require('bridge.download').download_bridge)
		-- Report progress messages back to the editor
		:on_yield(function(msg)
			vim.notify(tostring(msg), vim.log.levels.INFO)
		end)
end

return M
