local uv = vim.uv

---@class AsyncTask<T>
---@field co thread
---@field poll_pending any
---@field on_yield fun(value: T)|nil
---@field on_done fun(value: T)|nil
---@field timer uv_timer_t|nil
---@field start fun(self: AsyncTask<T>)
local AsyncTask = {}
AsyncTask.__index = AsyncTask

---@class Async
---@field poll_pending any
---@field use_schedule boolean
---@field use_uv boolean
local Async = {
	poll_pending = (coroutine.wrap(function()
		local ok, result = pcall(require('bridge.utils').load_bridge)
		if not ok or result == nil then
			vim.notify_once('Onoma did not load correctly: ' .. tostring(result), vim.log.levels.ERROR)
			return
		end
		return result.pending
	end))(),
	use_schedule = true,
	use_uv = true,
}

---@param opts { schedule?: boolean, uv?: boolean }
function Async.setup(opts)
	if opts.schedule ~= nil then
		Async.use_schedule = opts.schedule
	end
	if opts.uv ~= nil then
		Async.use_uv = opts.uv
	end
end

---@generic T
---@param fn fun(): T
---@return AsyncTask<T>
local function new_task(fn)
	local task = setmetatable({
		co = coroutine.create(fn),
		poll_pending = Async.poll_pending,
		timer = nil,
	}, AsyncTask)

	local function schedule(step)
		if Async.use_uv then
			if not task.timer then
				task.timer = uv.new_timer()
			end

			task.timer:start(0, 0, function()
				task.timer:stop()
				vim.schedule(step)
			end)
		elseif Async.use_schedule then
			vim.schedule(step)
		else
			step()
		end
	end

	local function step()
		local ok, value = coroutine.resume(task.co)
		if not ok then
			error('Coroutine error: ' .. tostring(value))
		end

		local dead = coroutine.status(task.co) == 'dead'

		if not dead and value ~= task.poll_pending and task.on_yield then
			task.on_yield(value)
		end

		if dead then
			if task.on_done then
				task.on_done(value)
			end
			if task.timer then
				task.timer:close()
			end
			return
		end

		schedule(step)
	end

	function task:start()
		step()
	end

	return task
end

--- Await final value (logically blocking, UI-safe)
---@generic T
---@return T
function AsyncTask:await()
	local result
	local done = false

	self.on_done = function(value)
		result = value
		done = true
	end

	self:start()

	vim.wait(1e9, function()
		return done
	end)

	return result
end

--- Run task without blocking
---@param opts? { on_yield?: fun(value:any), on_done?: fun(value:any) }
function AsyncTask:run(opts)
	opts = opts or {}
	self.on_yield = opts.on_yield
	self.on_done = opts.on_done or function() end
	self:start()
end

---@generic T
---@param fn fun(): T
---@return AsyncTask<T>
setmetatable(Async, {
	__call = function(_, fn)
		return new_task(fn)
	end,
})

return Async
