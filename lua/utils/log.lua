local function bridge()
	local bridge = require('bridge.utils').load_bridge()

	return bridge
end

return {
	trace = function(message)
		bridge().log('TRACE', message)
	end,
	debug = function(message)
		bridge().log('DEBUG', message)
	end,
	info = function(message)
		bridge().log('INFO', message)
	end,
	warn = function(message)
		bridge().log('WARN', message)
	end,
	error = function(message)
		bridge().log('ERROR', message)
	end,
	flush = function()
		bridge().flush()
	end,
}
