---@class onoma.SnacksProvider: onoma.Provider

---@param resolver onoma.Resolver
---@param opts onoma.Config
---@return snacks.picker.Config
local function get_symbols(resolver, opts)
	return vim.tbl_deep_extend('force', {
		live = true,
		title = opts.snacks.title,
		finder = function(picker, ctx)
			return require('providers.snacks.finder').get_symbols(resolver, picker, ctx, opts)
		end,
		format = require('providers.snacks.format').lsp_symbol,
		formatters = {
			file = {
				truncate = 'left',
			},
		},
		matcher = {
			sort_empty = true,
			fuzzy = false,
			smartcase = false,
			ignore_case = false,
			filename_bonus = false,
			file_pos = false,
		},
		sort = {
			fields = { 'score:desc' },
		},

		-- The lifecycle of the progress indicator will generally be managed by
		-- `finder.get_symbols`. However, if the finder is exited prematurely (before all
		-- symbols have been drawn), we might otherwise wind up not clearing the progress
		-- indicator - so clear it to make sure.
		on_close = require('utils.osc').clear_progress_indicator,

		debug = {
			scores = opts.debug, -- Show scores in the list
			leaks = opts.debug, -- Show when pickers don't get garbage collected
			explorer = opts.debug, -- Show explorer debug info
			files = opts.debug, -- Show file debug info
			grep = opts.debug, -- Show file debug info
			proc = opts.debug, -- Show proc debug info
			extmarks = opts.debug, -- Show extmarks errors
		},
	}, require('providers.snacks.layouts.' .. opts.snacks.layout).get_layout())
end

---@type onoma.SnacksProvider
return {
	setup = function(opts)
		local Async = require('utils.async')
		local Onoma = require('utils.onoma')
		local log = require('utils.log')

		if not Snacks or not pcall(require, 'snacks.picker') then
			error('Cannot register pickers as Snacks is not enabled')
		end

		local project_directory = { vim.fn.getcwd() }

		log.info('Initialising Snacks integration for: ' .. table.concat(project_directory, ', '))

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

		Snacks.picker.sources.get_symbols = get_symbols(resolver, opts)
	end,
}
