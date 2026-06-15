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
		local log = require('utils.log')

		local resolver, watcher = Async(function()
			return Onoma.new_resolver({ vim.fn.getcwd() }), Onoma.new_watcher({ vim.fn.getcwd() })
		end):await()

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

		return {
			get_symbols = function(opts)
				opts = vim.tbl_deep_extend('force', require('config'), opts == nil and {} or opts)

				pickers
					.new(opts, {
						results_title = opts.telescope.results_title,
						preview_title = opts.telescope.preview_title,
						prompt_title = opts.telescope.prompt_title,

						finder = finders.new_dynamic({
							entry_maker = function(entry)
								return entry
							end,
							fn = require('providers.telescope.finder').get_symbols(resolver, opts),
						}),
						sorter = require('telescope.sorters').Sorter:new({
							discard = false,
							scoring_function = function(_, _, ordinal)
								return 1 / ordinal
							end,
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
