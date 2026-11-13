local M = {}

---@class onoma.TelescopeProvider: onoma.Provider
---@field register_extension fun(): table

local finders = require('telescope.finders')
local pickers = require('telescope.pickers')

---@type onoma.Resolver
local resolver
---@type onoma.Config
local opts

function M.setup(r, _, o)
	resolver = r
	opts = vim.tbl_deep_extend('force', require('config'), o == nil and {} or o)
end

---@return table
function M.register_extension()
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
end

---@type onoma.TelescopeProvider
return M
