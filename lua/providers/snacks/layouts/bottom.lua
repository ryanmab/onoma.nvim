local M = {}

---@return { layout: snacks.picker.layout.Config, layouts: table<string, snacks.picker.layout.Config> }
function M.get_layout()
	return {
		layout = {
			reverse = true,
			preview = 'main',
			cycle = false,
			layout = {
				box = 'vertical',
				backdrop = false,
				row = -1,
				width = 0,
				height = 0.25,
				{ win = 'preview', title = '{preview}' },
				{
					win = 'list',
					border = { '', ' ', '', '', '', ' ', '', '' },
					wo = {
						-- Blend border into Picker background
						winhighlight = 'FloatBorder:SnacksPicker',
					},
				},
				{ win = 'input', height = 1 },
			},
		},
		win = {
			preview = {
				wo = {
					-- Preserve the status line in the preview window
					statusline = vim.o.statusline,
				},
			},
		},
	}
end

return M
