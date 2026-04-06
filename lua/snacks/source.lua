local M = {}

---@return snacks.picker.Config
function M.get_source(opts, resolver)
	local finder = require('snacks.finder')
	local format = require('snacks.format')

	local osc = require('utils.osc')

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

		-- The lifecycle of the progress indicator will generally be managed by
		-- `finder.get_symbols`. However, if the finder is exited prematurely (before all
		-- symbols have been drawn), we might otherwise wind up not clearing the progress
		-- indicator - so clear it to make sure.
		on_close = osc.clear_progress_indicator,
	}
end

return M
