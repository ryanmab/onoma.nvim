local finders = require('telescope.finders')
local pickers = require('telescope.pickers')

---@class onoma.TelescopeProviderSetup
---@field get_symbols fun(opts: onoma.Config)

---@class onoma.TelescopeProvider: onoma.Provider
---@field setup fun(): onoma.TelescopeProviderSetup

---@type onoma.TelescopeProvider
return {
	setup = function()
		local Async = require('utils.async')
		local Onoma = require('utils.onoma')

		local project_directory = { vim.fn.getcwd() }

		local resolver, watcher = unpack(Async(function()
			return {
				Onoma.new_resolver(project_directory),
				Onoma.new_watcher(project_directory),
			}
		end):await())

		Async(function()
			-- Start a new watcher asynchronously, ready to index files for
			-- the resolver to consume
			watcher:start()
		end):run()

		return {
			get_symbols = function(opts)
				opts = vim.tbl_deep_extend('force', require('config'), opts == nil and {} or opts)

				pickers
					.new(opts, {
						results_title = opts.telescope.results_title,
						preview_title = opts.telescope.preview_title,
						prompt_title = opts.telescope.prompt_title,

						finder = finders.new_dynamic({
							entry_maker = require('providers.telescope.format').lsp_symbol(),
							fn = require('providers.telescope.finder').get_symbols(resolver, opts),
						}),
						sorter = require('telescope.sorters').Sorter:new({
							discard = false,
							scoring_function = function(_, _, ordinal)
								return 1 / ordinal
							end,
							highlighter = require('providers.telescope.format').substr_highlighter(),
						}),
						previewer = require('telescope.config').values.qflist_previewer({}),
						tiebreak = function()
							return false
						end,
					})
					:find()
			end,
		}
	end,
}
