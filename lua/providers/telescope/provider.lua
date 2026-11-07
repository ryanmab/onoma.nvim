local finders = require('telescope.finders')
local pickers = require('telescope.pickers')

---@class onoma.TelescopeProviderSetup
---@field get_symbols fun(opts: onoma.Config)

---@class onoma.TelescopeProvider: onoma.Provider
---@field register_extension fun(): table

local resolver
local opts

---@type onoma.TelescopeProvider
local M = {
	setup = function(r, _, o)
		resolver = r
		opts = vim.tbl_deep_extend('force', require('config'), o == nil and {} or o)
	end,
	register_extension = function()
		return require('telescope').register_extension({
			exports = {
				get_symbols = function()
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
			},
		})
	end,
}

return M
