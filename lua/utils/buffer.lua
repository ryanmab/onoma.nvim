local M = {}

-- Get the path to the file open to the current focused buffer, ignoring ones
-- which are not loaded.
--
---@return string|nil
function M.current_buffer_path()
	local buf = vim.api.nvim_get_current_buf()

	if not vim.api.nvim_buf_is_loaded(buf) then
		return nil
	end

	local name = vim.api.nvim_buf_get_name(buf)

	if name == '' then
		return nil
	end

	return name
end

return M
