local M = {}

---@return { layout: snacks.picker.layout.Config }
function M.get_layout()
	return {
		layout = {
			cycle = true,
			preset = function()
				--- Use the default layout or vertical if the window is too narrow
				return vim.o.columns >= 120 and 'default' or 'vertical'
			end,
		},
	}
end

return M
