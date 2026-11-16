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

	local resolver, watcher = unpack(Async(function()
		local ok, resolver = pcall(onoma.new_resolver, directories)
		if not ok then
			error('Failed to create resolver: ' .. resolver)
		end

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

function setup_user_commands()
	vim.api.nvim_create_user_command('Onoma', function(opts)
		local command = opts.fargs[1]

		if command == 'build' then
			vim.schedule(function()
				M.build():run()
			end)
		end
	end, { nargs = 1 })
end

---@param opts onoma.Config
function M.setup(opts)
	setup_user_commands()

	opts = vim.tbl_deep_extend('force', require('config'), opts == nil and {} or opts)

	local ok, bridge = pcall(require('bridge.utils').load_bridge)

	if not ok then
		-- We couldn't start setup as the bridge failed to load.
		--
		-- NB: we can't even use the logging utils here as they rely
		-- on the bridge being loaded.
		vim.notify('Setup failed: ' .. bridge, vim.log.levels.ERROR)

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

		return
	end

	local project_directory = { vim.fn.getcwd() }
	local ok, init = pcall(initialise_onoma, project_directory)

	if not ok then
		log.error('Failed to initialise onoma: ' .. init)

		return
	end

	local resolver, watcher = unpack(init)

	for _, picker in ipairs(pickers) do
		---@type boolean, onoma.Provider
		local ok, provider = pcall(require, 'providers.' .. picker .. '.provider')

		if not ok or provider == nil then
			error('No provider for picker: ' .. picker)
		end

		local ok, err = pcall(provider.setup, resolver, watcher, opts)

		if not ok then
			error('Failed to setup picker (' .. picker .. '): ' .. err)
		end
	end
end

function M.build()
	local Async = require('utils.async')
	local download = require('bridge.download')

	return Async(download.download_bridge)
		-- Report progress messages back to the editor
		:on_yield(function(msg)
			vim.notify(tostring(msg), vim.log.levels.INFO)
		end)
end

return M
