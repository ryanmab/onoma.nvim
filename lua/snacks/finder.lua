local SnacksAsync = require('snacks.picker.util.async')
local buffer = require('utils.buffer')

local M = {}

---@param opts table
---@param resolver onoma.Resolver
---@param _ any
---@param ctx table|nil
---
---@return nil|fun(cb: fun(item: snacks.picker.Item)): nil
function M.get_symbols(opts, resolver, _, ctx)
	local ok, onoma = pcall(require('bridge.utils').load_bridge)
	if not ok or onoma == nil then
		vim.notify_once('Onoma did not load correctly: ' .. onoma, vim.log.levels.ERROR)
		return
	end

	---@type onoma.QueryContext
	local context = onoma.create_context(buffer.current_buffer_path(), opts.finder.symbol_kinds)

	return function(cb)
		local query = (ctx and ctx.filter and ctx.filter.search) or ''

		local stream = resolver:query(query, context)

		---@async
		while true do
			local item = stream:next()

			if item == nil then
				-- Stream finished, we can return
				break
			elseif type(item) == 'userdata' then
				---@cast item onoma.ResolvedSymbol
				cb({
					idx = item.id,
					kind = item.kind,
					name = item.name,
					text = item.name,
					file = item.path,
					score = 0,
					score_add = item.score,
					score_mul = 1,
					pos = { item.start_line, item.start_column - 1 },
					end_pos = { item.end_line, item.end_column - 1 },
				})

				SnacksAsync.yield()
			else
				-- Suspend for anything else - usually this will be Async._poll_pending (originating from Rust
				-- async)
				SnacksAsync.suspend()
			end
		end
	end
end

return M
