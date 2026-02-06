local constants = require('constant')

local M = {}

-- Detect CPU architecture for target.
--
-- Matches to architecture formats for Rust targets: https://github.com/ryanmab/onoma.nvim/blob/main/.github/workflows/release-drafter.yml
--
---@return string|false
local function detect_arch()
	local arch = jit.arch

	if arch == 'x64' then
		return 'x86_64'
	elseif arch == 'arm64' or arch == 'aarch64' then
		return 'aarch64'
	end

	return false
end

-- Detect operating system for target
--
-- Matches to architecture formats for Rust targets: https://github.com/ryanmab/onoma.nvim/blob/main/.github/workflows/release-drafter.yml
--
---@return (string, string)|false
local function detect_os()
	local os = jit.os

	if os == 'OSX' then
		return 'apple-darwin', 'dylib'
	elseif os == 'Linux' then
		return 'unknown-linux', 'so'
	elseif os == 'Windows' then
		return 'pc-windows-msvc', 'dll'
	end

	return false
end

-- Detect libc variant on Linux
--
-- Matches to architecture formats for Rust targets: https://github.com/ryanmab/onoma.nvim/blob/main/.github/workflows/release-drafter.yml
--
--- @return "gnu" | "musl"
local function detect_linux_libc()
	-- musl loader exists, we can bail here.
	if vim.fn.glob('/lib/ld-musl-*.so*') ~= '' then
		return 'musl'
	end

	-- Check ldd output for musl any mentions of musl
	local handle = io.popen('ldd --version 2>&1')
	if handle then
		local output = handle:read('*a')
		handle:close()

		if output:lower():find('musl') then
			return 'musl'
		end
	end

	return 'gnu'
end

-- Get the correct target for the current operating system and architecture.
--
-- Currently supports:
-- 1. MacOS (Apple Silicon and Intel)
-- 2. Windows (x86 and ARM)
-- 3. Linux (x86 and ARM)
--
-- Matches to architecture formats for Rust targets: https://github.com/ryanmab/onoma.nvim/blob/main/.github/workflows/release-drafter.yml
--
---@return { target: string, architecture: string, operating_system: string, extension: string }
function M.get_target()
	local arch = detect_arch()
	local os, ext = detect_os()

	if arch == false or os == false then
		error('Unable to load Onoma. Unable to determine target: ' .. os .. ' (' .. arch .. ')')
	end

	if os == 'unknown-linux' then
		local libc = detect_linux_libc()

		return {
			target = string.format('%s-%s-%s.%s', arch, os, libc, ext),
			architecture = arch,
			operating_system = os,
			extension = ext,
		}
	end

	return {
		target = string.format('%s-%s.%s', arch, os, ext),
		architecture = arch,
		operating_system = os,
		extension = ext,
	}
end

-- Get the path to the bridge binary.
--
---@return string
function M.get_bridge_path()
	local plugin_directory = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h:h')

	return plugin_directory .. '/bridge/target/release'
end

-- Load the bridge binary for use in Lua code.
--
---@return onoma.Bridge|nil
function M.load_bridge()
	local ok, result = pcall(M.get_target)

	if not ok then
		error(string.format('Error loading library from %s: %s', result))
		return
	end

	local lib = M.get_bridge_path() .. '/lib' .. constants.LIBRARY_NAME .. '.' .. result.extension

	local loader, load_err = package.loadlib(lib, 'luaopen_onoma_bridge')

	if load_err then
		error(string.format('Error loading library from %s: %s', lib, load_err))
		return
	end

	local onoma, run_err = loader()

	if run_err then
		error(string.format('Error calling loader from %s: %s', lib, run_err))
		return
	end

	return onoma
end

return M
