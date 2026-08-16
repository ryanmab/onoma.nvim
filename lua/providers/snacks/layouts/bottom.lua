local M = {}

---@return { layout: snacks.picker.layout.Config, layouts: table<string, snacks.picker.layout.Config> }
function M.get_layout()
	return {
		layout = {
			reverse = true,
			preview = 'main',
			preset = 'bottom',
		},
		layouts = {
			bottom = {
				layout = {
					box = 'vertical',
					backdrop = false,
					row = -1,
					width = 0,
					height = 0.25,
					{ win = 'list', height = 1 },
					{
						box = 'horizontal',
						{ win = 'list', border = 'none' },
						{ win = 'preview', title = '{preview}' },
					},
					{ win = 'input', height = 1, border = 'none' },
				},
			},
		},
	}
end

return M
