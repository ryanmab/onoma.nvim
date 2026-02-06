local function onoma()
	local ok, onoma = pcall(require('bridge.utils').load_bridge)
	if not ok or onoma == nil then
		vim.notify_once('Onoma did not load correctly: ' .. onoma, vim.log.levels.ERROR)
		return
	end

	return onoma
end

return {
	trace = function(message)
		onoma().log('TRACE', message)
	end,
	debug = function(message)
		onoma().log('DEBUG', message)
	end,
	info = function(message)
		onoma().log('INFO', message)
	end,
	warn = function(message)
		onoma().log('WARN', message)
	end,
	error = function(message)
		onoma().log('ERROR', message)
	end,
}
