return require('telescope').register_extension({
	exports = require('providers.telescope.provider').setup(),
})
