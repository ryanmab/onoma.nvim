local constant = require('constant')
local utils = require('bridge.utils')

local M = {}

-- Get the release tag which assets should be downloaded from.
--
---@param cwd string: the current working directory
---@return string|nil
function M.get_release_tag(cwd)
	local args = {
		'cd ' .. cwd .. ' && ',
		'git',
		'describe',
		'--tags',
		'--exact-match',
	}
	local command = table.concat(args, ' ')

	local handle = io.popen(command)

	if not handle then
		error('Failed to get git tag for HEAD')
	end

	local output = handle:read('*a')
	handle:close()

	local lines = vim.split(output, '\n')

	if lines[1] == '' then
		return nil
	end

	return lines[1]
end

---@return string|nil
function M.get_downloaded_release_tag()
	local tag_file = utils.get_bridge_path() .. '/' .. constant.TAG_FILE
	local f, err = io.open(tag_file, 'r')

	if not f then
		-- Tag file does not exist, treat as no tag
		return nil
	end

	local tag = f:read('*l')
	f:close()

	if tag == '' then
		-- Empty tag file, treat as no tag
		return nil
	end

	return tag
end

---@param release_tag string
function M.update_downloaded_release_tag(release_tag)
	local path = utils.get_bridge_path()

	vim.uv.fs_open(path .. '/' .. constant.TAG_FILE, 'w', 438, function(open_err, fd)
		if open_err or fd == nil then
			error('Failed to open tag file: ' .. (open_err and open_err.message or 'unknown error'))
			return
		end

		vim.uv.fs_write(fd, release_tag, 0, function(write_err)
			vim.uv.fs_close(fd, function() end)
			if write_err then
				error('Failed to write tag file: ' .. write_err.message)
				return
			end
		end)
	end)
end

-- Get the URL for a release asset.
--
---@param owner string: the GitHub owner name
---@param repository string: the GitHub repository name
---@param target string: the target asset name
---@param is_checksum boolean: whether to get the .sha256 checksum file
---
---@return string
function M.get_release_asset_url(owner, repository, release_tag, target, is_checksum)
	if is_checksum then
		target = target .. '.sha256'
	end

	return string.format('https://github.com/%s/%s/releases/download/%s/%s', owner, repository, release_tag, target)
end

-- Verifies a binary against its .sha256 file
--
---@param binary_path string: full path to the binary
---@param checksum_file string: full path to the .sha256 file
function M.verify_checksum(binary_path, checksum_file)
	local f, err = io.open(checksum_file, 'r')

	if not f then
		error('Failed to open checksum file: ' .. err)
	end

	local content = f:read('*l') -- read first line
	f:close()

	local expected = content:match('^([a-fA-F0-9]+)')
	if not expected then
		error('Invalid checksum file format: ' .. checksum_file)
	end
	expected = expected:lower()

	local cmd = string.format('sha256sum "%s" 2>&1', binary_path)

	local handle = io.popen(cmd)
	local output = handle:read('*a')
	handle:close()

	if not output or output == '' then
		error('Failed to run sha256sum on ' .. binary_path)
	end

	local actual = output:match('^([a-fA-F0-9]+)')
	if not actual then
		error('Failed to parse sha256sum output: ' .. output)
	end

	actual = actual:lower()

	return actual == expected
end

return M
