local buffer = require('utils.buffer')
local osc = require('utils.osc')

local M = {}

---@param resolver onoma.Resolver
---@param opts onoma.Config
function M.get_symbols(resolver, opts)
	local Async = require('utils.async')
	local ok, onoma = pcall(require('bridge.utils').load_bridge)
	if not ok or onoma == nil then
		vim.notify_once('Onoma did not load correctly: ' .. onoma, vim.log.levels.ERROR)
		return
	end

	---@type onoma.QueryContext
	local context = onoma.create_context(buffer.current_buffer_path(), opts.symbol_kinds or nil)

	return function(query)
		return Async(function()
			local locations = {}

			osc.set_progress_indicator(nil)
			local stream = resolver:query(query, context)

			while true do
				local item = stream:next()

				if item == nil then
					-- Stream finished, we can return
					osc.clear_progress_indicator()
					break
				end

				if type(item) == 'userdata' then
					---@cast item onoma.ResolvedSymbol
					table.insert(locations, {
						-- There is a bug in Telescope which means multi-line results
						-- cause unhandled cursor position errors, and so, we need to strip
						-- out any new lines from the result before it is returned.
						--
						--  By convention multiline symbols will be returned by Onoma (where
						--  _only_ trailing whitespace is guaranteed to be removed).
						--
						-- See: https://github.com/nvim-telescope/telescope.nvim/issues/3163#issuecomment-2167678288
						symbol_name = item.name:gsub('\n', ' '),
						symbol_kind = item.kind,
						path = item.path,

						ordinal = item.score,
						lnum = item.start_line,
						col = item.start_column,
					})
				end
			end

			return locations
		end):await()
	end
end

return M
