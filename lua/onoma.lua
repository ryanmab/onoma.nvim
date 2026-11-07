local M = {}

---@return { resolver: onoma.Resolver, watcher: onoma.Watcher }
local function initialise_onoma()
	local Async = require('utils.async')
	local Onoma = require('utils.onoma')
	local log = require('utils.log')

	local project_directory = { vim.fn.getcwd() }

	log.info('Initialising integration for: ' .. table.concat(project_directory, ', '))

	local resolver, watcher = unpack(Async(function()
		local ok, resolver = pcall(Onoma.new_resolver, project_directory)
		if not ok then
			log.error('Failed to create resolver: ' .. resolver)
			return { nil, nil }
		end

		local ok, watcher = pcall(Onoma.new_watcher, project_directory)
		if not ok then
			log.error('Failed to create watcher: ' .. watcher)
			return { nil, nil }
		end

		return {
			resolver,
			watcher,
		}
	end):await())

	Async(function()
		local ok, err = pcall(watcher.start, watcher)

		if not ok then
			log.error('Failed to start watcher: ' .. err)
		end

		local ok, err = pcall(watcher.run_full_index, watcher)

		if not ok then
			log.error('Failed to run full index: ' .. err)
		end
	end):run()

	return {
		resolver,
		watcher,
	}
end

---@param opts onoma.Config
function M.setup(opts)
	local onoma = require('utils.onoma')
	local log = require('utils.log')

	opts = vim.tbl_deep_extend('force', require('config'), opts == nil and {} or opts)

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

	local resolver, watcher = unpack(initialise_onoma())

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

return M
