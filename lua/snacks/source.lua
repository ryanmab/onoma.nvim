local M = {}

---@return snacks.picker.Config
function M.get_source(opts, resolver)
	local finder = require('snacks.finder')
	local format = require('snacks.format')

	return {
		title = opts.snacks.source.title,
		live = true,
		finder = function(picker, ctx)
			return finder.get_symbols(opts, resolver, picker, ctx)
		end,
		format = format.lsp_symbol,
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
		debug = opts.snacks.source.debug,
	}
end

return M
