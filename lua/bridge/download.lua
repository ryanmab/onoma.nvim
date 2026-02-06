local M = {}

local constants = require('constant')
local git = require('bridge.git')
local utils = require('bridge.utils')

-- @return boolean
local function file_exists(path)
	local f = io.open(path, 'rb')

	if f then
		f:close()
	end

	return f ~= nil
end

-- Download a file from a URL to an output path using curl.
--
---@param url string
---@param output_file string
--
---@return nil
local function download(url, output_file)
	local args = {
		'curl',
		'-fL',
		'--silent',
		'--show-error',
		'--retry',
		'3',
		'--retry-delay',
		'1',
		'-o',
		output_file,
		url,
	}

	local command = table.concat(args, ' ')

	-- Capture stderr and stdout so that they can be yielded to the calling coroutine
	-- (which in practice will be Lazy.nvim's build coroutine that'll show this in a UI)
	local handle = io.popen(command .. ' 2>&1')

	if handle == nil then
		error('Command failed: ' .. command)
	end

	local output = handle:read('*a')
	local ok, _, _ = handle:close()

	if not (output == '' or output == nil) then
		coroutine.yield(output)
	end

	if not ok then
		error('Command failed: ' .. command)
	end
end

---@param owner string
---@param repository string
---@param release_tag string
---@return string
local function download_or_return_bridge(owner, repository, release_tag)
	local target = utils.get_target()

	if not target then
		error('Unable to determine target: ' .. jit.os .. ' (' .. jit.arch .. ')')
	end

	local bridge_path = utils.get_bridge_path()

	vim.fn.mkdir(bridge_path, 'p')

	local bridge_file = bridge_path .. '/lib' .. constants.LIBRARY_NAME .. '.' .. target.extension

	if file_exists(bridge_file) and git.get_downloaded_release_tag() == release_tag then
		coroutine.yield('Bridge is already downloaded: ' .. release_tag)

		return bridge_file
	end

	coroutine.yield('Downloading bridge…')

	download(git.get_release_asset_url(owner, repository, release_tag, target.target, false), bridge_file)

	coroutine.yield('Bridge downloaded successfully')

	return bridge_file
end

---@param owner string
---@param repository string
---@return string
local function download_or_return_checksum(owner, repository, release_tag)
	local target = utils.get_target()
	local bridge_path = utils.get_bridge_path()

	vim.fn.mkdir(bridge_path, 'p')

	local checksum_file = bridge_path .. '/lib' .. constants.LIBRARY_NAME .. '.' .. target.extension .. '.sha265'

	if file_exists(checksum_file) and git.get_downloaded_release_tag() == release_tag then
		coroutine.yield('Bridge checksum is already downloaded: ' .. release_tag)

		return checksum_file
	end

	coroutine.yield('Downloading bridge checksum…')

	download(git.get_release_asset_url(owner, repository, release_tag, target.target, true), checksum_file)

	coroutine.yield('Bridge checksum downloaded successfully')

	return checksum_file
end

-- Download bridge from GitHub (if necessary) and verify it against
-- using its checksum.
function M.download_bridge()
	local ok, result

	-- Get the root directory of the plugin, by getting the relative path to this file and traversing
	-- up one directory (from lua/bridge/download.lua to lua/)
	local root_path = vim.fn.resolve(debug.getinfo(1).source:match('@?(.*/)') .. '../')

	local release_tag = git.get_release_tag(root_path)

	if release_tag == nil then
		coroutine.yield(
			'You must be using a specific release to make use of pre-built binaries. Otherwise you need to build from source.'
		)
		return
	end

	ok, result = pcall(download_or_return_bridge, constants.REPOSITORY_OWNER, constants.REPOSITORY_NAME, release_tag)
	if not ok then
		coroutine.yield('Failed to download bridge: ' .. result)
		return
	end
	local bridge_file = result

	ok, result = pcall(download_or_return_checksum, constants.REPOSITORY_OWNER, constants.REPOSITORY_NAME, release_tag)
	if not ok then
		os.remove(bridge_file)

		coroutine.yield('Failed to download bridge checksum: ' .. result)
		return
	end
	local checksum_file = result

	ok, result = pcall(git.verify_checksum, bridge_file, checksum_file)

	if not ok then
		os.remove(bridge_file)
		os.remove(checksum_file)

		coroutine.yield('Failed to verify bridge against checksum: ' .. result)
		return
	end

	if not result then
		os.remove(bridge_file)
		os.remove(checksum_file)

		coroutine.yield('Downloaded bridge did not match expected checksum')
		return
	end

	-- Update the stored release tag so that any future runs know what version
	-- the bridge is currently on
	pcall(git.update_downloaded_release_tag, release_tag)

	if vim.fn.has('win32') == 0 then
		vim.fn.setfperm(bridge_file, 'rwxr-xr-x')
	end

	coroutine.yield('Bridge validated against checksum. Onoma is now ready to use')
end

return M
