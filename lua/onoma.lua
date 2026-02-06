---@class onoma.Watcher
---@field start fun(self: onoma.Watcher): nil Starts the watcher asynchronously.
---@field stop_blocking fun(self: onoma.Watcher): nil Stops the watcher

---@class onoma.Resolver
---@field query fun(self: onoma.Resolver, query: string, context: onoma.QueryContext): onoma.ReceiverStream Queries symbols based on the provided query and context.

---@class onoma.QueryContext
---@field file_path string|nil The path of the current file focussed (if any).
---@field symbol_kinds onoma.SymbolKind[] The kinds of symbols to include in the query

---@class onoma.ReceiverStream
---@field next fun(self: onoma.ReceiverStream): onoma.ResolvedSymbol|nil|any Retrieves the next symbol from the stream. Returns nil when the stream is exhausted.

---@class onoma.ResolvedSymbol
---@field id number The unique identifier of the symbol.
---@field kind onoma.SymbolKind The kind of the symbol (e.g., function, variable, class).
---@field name string The name of the symbol.
---@field path string The file path where the symbol is located.
---@field start_line number The starting line number of the symbol in the file.
---@field start_column number The starting column number of the symbol in the file.
---@field end_line number The ending line number of the symbol in the file.
---@field end_column number The ending column number of the symbol in the file.
---@field score number The relevance score of the symbol for the query.

---@class onoma.Bridge
---@field get_watcher fun(directories: string[]): onoma.Watcher Creates a watcher for the specified directories.
---@field get_resolver fun(directories: string[]): onoma.Resolver Creates a resolver
---@field create_context fun(file_path: string|nil, symbol_kinds: onoma.SymbolKind[]): onoma.QueryContext Creates a query context.
---@field log fun(level: 'TRACE' |'DEBUG' | 'INFO' | 'WARN' | 'ERROR', message: string): nil Logs a message from the Onoma bridge.
---@field pending userdata A handle to be used for async operations.

local M = {
	state = {
		---@type onoma.Watcher|nil
		watcher = nil,

		---@type onoma.Resolver|nil
		resolver = nil,
	},
}

---@param opts table|nil
function M.setup(opts)
	local Async = require('utils.async')
	local log = require('utils.log')
	local source = require('snacks.source')
	local utils = require('bridge.utils')

	local opts = vim.tbl_deep_extend('force', require('config'), opts or {})
	local directories = { vim.fn.getcwd() }

	local ok, onoma = pcall(utils.load_bridge)
	if not ok or onoma == nil then
		vim.notify_once('Onoma did not load correctly: ' .. onoma, vim.log.levels.ERROR)
		return
	end

	Async(function()
		M.state.resolver = onoma.get_resolver(directories)
		log.debug('Resolver created at: ' .. os.date('%Y-%m-%d %H:%M:%S'))
	end):run()

	Async(function()
		M.state.watcher = onoma.get_watcher(directories)
		log.debug('Watcher created at: ' .. os.date('%Y-%m-%d %H:%M:%S'))

		if not M.state.watcher then
			log.error('Failed to create watcher for directories: ' .. table.concat(directories, ', '))
			return
		end

		local ok, err = pcall(M.state.watcher.start, M.state.watcher)
		if not ok then
			log.error('Failed to start watcher: ' .. tostring(err))
		end

		log.debug('Watcher started successfully for directories: ' .. table.concat(directories, ', '))
	end):run()

	vim.api.nvim_create_autocmd('VimLeavePre', {
		group = vim.api.nvim_create_augroup('onoma_watcher', { clear = true }),
		callback = function()
			log.trace('Vim is exiting')

			if M.state.watcher then
				local ok, err = pcall(M.state.watcher.stop_blocking, M.state.watcher)
				if not ok then
					log.error('Failed to stop watcher: ' .. tostring(err))
					return
				end

				log.debug('Watcher has been cleaned up')
			end
		end,
	})

	if Snacks and pcall(require, 'snacks.picker') then
		Snacks.picker.sources.onoma = source.get_source(opts, M.state.resolver)
	end
end

return M
