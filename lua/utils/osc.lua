local M = {}

--- Update the OSC 9;4 progress indicator.
---
--- This reflects a progress bar in supported terminals (e.g. Ghostty).
---
--- If `nil` is provided for the percentage, the indicator shows in the indeterminante state.
---
--- https://learn.microsoft.com/en-us/windows/terminal/tutorials/progress-bar-sequences
---
---@param percentage number|nil
function M.set_progress_indicator(percentage)
	if percentage then
		vim.schedule(function()
			vim.api.nvim_ui_send(string.format('\027]9;4;1;%d\027\\', percentage))
		end)
	else
		vim.schedule(function()
			vim.api.nvim_ui_send('\027]9;4;3\027\\')
		end)
	end
end

-- Clear the OSC 9;4 progress indicator.
function M.clear_progress_indicator()
	vim.schedule(function()
		vim.api.nvim_ui_send('\027]9;4;0\027\\')
	end)
end

return M
