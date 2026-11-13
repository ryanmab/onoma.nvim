local M = {}

---@class onoma.MiniProvider: onoma.Provider

---@param resolver onoma.Resolver
---@param opts onoma.Config
local function create_get_symbols_callback(resolver, opts)
	local Async = require('utils.async')
	local onoma = require('bridge.utils').load_bridge()
	local buffer = require('utils.buffer')
	local osc = require('utils.osc')

	local namespace_id = vim.api.nvim_create_namespace('OnomaMiniPicker')

	return function()
		---@type onoma.QueryContext
		local context = onoma.create_context(buffer.current_buffer_path(), opts.symbol_kinds or nil)

		MiniPick.start({
			source = {
				items = {},
				name = 'Symbols',
				show = function(buf_id, items_to_show, query)
					-- Highlight whole lines with pre-computed symbol kind highlight groups
					MiniPick.default_show(buf_id, items_to_show, query, { show_icons = true })

					-- Apply symbol kind highlights
					pcall(vim.api.nvim_buf_clear_namespace, buf_id, namespace_id, 0, -1)

					for i, item in ipairs(items_to_show) do
						vim.api.nvim_buf_set_extmark(
							buf_id,
							namespace_id,
							i - 1,
							0,
							{ end_row = i, end_col = 0, hl_mode = 'blend', hl_group = item.hl, priority = 199 }
						)
					end
				end,
				match = function(_, _, query)
					local query, querytick = table.concat(query), MiniPick.get_querytick()

					osc.set_progress_indicator(nil)

					local set_picker_items = function(items)
						table.sort(items, function(a, b)
							return a.score > b.score
						end)

						MiniPick.set_picker_items(items, { do_match = false, querytick = querytick })
					end

					Async(function()
						local stream = resolver:query(query, context)
						local items = {}

						while true do
							local result = stream:next()

							if not MiniPick.is_picker_active() then
								stream:close()
								osc.clear_progress_indicator()
								return
							end

							if result == nil then
								osc.clear_progress_indicator()
								set_picker_items(items)
								return
							end

							if MiniPick.get_querytick() ~= querytick then
								-- Picker has been superseded, so we don't want to clear the progress
								-- indicator
								stream:close()
								return
							end

							if type(result) == 'userdata' then
								---@cast result onoma.ResolvedSymbol
								items[#items + 1] = {
									type = 'file',
									text = result.name,
									path = result.path,
									lnum = result.start_line,
									end_lnum = result.end_line,
									col = result.start_column,
									hl = string.lower(result.kind or 'unknown'),
									end_col = result.end_column,
									kind = result.kind,
									score = result.score,
								}

								if opts.mini.batch_size and #items % opts.mini.batch_size == 0 then
									set_picker_items(items)
								end
							end
						end
					end):run()
				end,
			},
		})
	end
end

function M.setup(resolver, _, opts)
	if not MiniPick then
		error('Cannot register pickers as Mini is not enabled')
	end

	MiniPick.registry.get_symbols = create_get_symbols_callback(resolver, opts)
end

---@type onoma.MiniProvider
return M
