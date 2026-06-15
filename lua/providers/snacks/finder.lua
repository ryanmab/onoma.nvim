local M = {}

---@param resolver onoma.Resolver
---@param _ any
---@param ctx table|nil
---@param opts onoma.Config
---
---@return nil|(fun(cb: fun(item: snacks.picker.Item)): nil)|(onoma.ResolvedSymbol[])
function M.get_symbols(resolver, _, ctx, opts)
	local buffer = require('utils.buffer')
	local osc = require('utils.osc')

	local ok, onoma = pcall(require('bridge.utils').load_bridge)
	if not ok or onoma == nil then
		vim.notify_once('Onoma did not load correctly: ' .. onoma, vim.log.levels.ERROR)
		return
	end

	---@type onoma.QueryContext
	local context = onoma.create_context(buffer.current_buffer_path(), opts.symbol_kinds or nil)

	return function(cb)
		local query = (ctx and ctx.filter and ctx.filter.search) or ''

		osc.set_progress_indicator(nil)
		local stream = resolver:query(query, context)

		---@async
		while true do
			local result = stream:next()

			if result == nil then
				-- Stream finished, we can return
				osc.clear_progress_indicator()
				break
			end

			if type(result) == 'userdata' then
				---@cast result onoma.ResolvedSymbol
				cb({
					idx = result.id,
					kind = result.kind,
					name = result.name,
					text = result.name,
					file = result.path,
					score = 0,
					score_add = result.score,
					score_mul = 1,
					pos = { result.start_line, result.start_column - 1 },
					end_pos = { result.end_line, result.end_column - 1 },
				})
			end

			-- NB: Theres no SnacksAsync.yield` or `SnacksAsync.suspend` here because
			-- the bridge returns symbols fast enough that yielding in Lua will cause
			-- heavy context switching between coroutines which noticeably shows down
			-- the picker.
		end
	end
end

return M
