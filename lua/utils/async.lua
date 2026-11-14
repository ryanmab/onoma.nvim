local uv = vim.uv

---@class AsyncTask<T>
---@field co thread
---@field poll_pending any
---@field _on_yield fun(value: any)|nil
---@field _on_done fun(value: T)|nil
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
		local ok, onoma = pcall(require('bridge.utils').load_bridge)

		if not ok then
			-- The bridge is likely to not be available during builds, which also
			-- run asynchronously. Where we don't have a bridge, we know that we can't have
			-- any coroutines return the pending value, and so we don't need to observe it.
			return nil
		end

		return onoma.pending
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
		_on_yield = nil,
		_on_done = nil,
		timer = nil,
	}, AsyncTask)

	local function cleanup_timer()
		if task.timer then
			task.timer:stop()
			if not task.timer:is_closing() then
				task.timer:close()
			end
			task.timer = nil
		end
	end

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
			cleanup_timer()
			vim.notify('Async error: ' .. tostring(value), vim.log.levels.ERROR)

			if task._on_done then
				task._on_done(nil)
			end

			return
		end

		local dead = coroutine.status(task.co) == 'dead'

		if not dead and (value ~= task.poll_pending or type(task.poll_pending) ~= 'userdata') and task._on_yield then
			task._on_yield(value)
		end

		if dead then
			cleanup_timer()
			if task._on_done then
				task._on_done(value)
			end
			return
		end

		schedule(step)
	end

	function task:start()
		schedule(step)
	end

	return task
end

--- Register a handler for yielded progress values (chainable)
---@param fn fun(value: any)
---@return AsyncTask<T>
function AsyncTask:on_yield(fn)
	self._on_yield = fn
	return self
end

--- Register a completion callback (chainable)
---@param fn fun(value: T)
---@return AsyncTask<T>
function AsyncTask:on_done(fn)
	self._on_done = fn
	return self
end

--- Await final value (logically blocking, UI-safe)
--- If `:on_yield(coroutine.yield)` is set inside an active coroutine,
--- steps cooperate so yielded values are returned to the caller and
--- the final value is returned when the task is complete.
---@generic T
---@return T
function AsyncTask:await()
	if self._on_yield == coroutine.yield and coroutine.running() ~= nil then
		while true do
			local ok, value = coroutine.resume(self.co)
			if not ok then
				error(value, 2)
			end

			if coroutine.status(self.co) == 'dead' then
				if self._on_done then
					self._on_done(value)
				end
				return value
			end

			if value ~= self.poll_pending then
				coroutine.yield(value)
			else
				coroutine.yield()
			end
		end
	end

	local result
	local done = false
	local on_done = self._on_done

	self._on_done = function(value)
		result = value
		done = true
		if on_done then
			on_done(value)
		end
	end

	self:start()

	vim.wait(1e9, function()
		return done
	end)

	return result
end

--- Run task without blocking
---@param opts? { on_yield?: fun(value: any), on_done?: fun(value: T) }
function AsyncTask:run(opts)
	opts = opts or {}
	if opts.on_yield then
		self._on_yield = opts.on_yield
	end
	if opts.on_done then
		self._on_done = opts.on_done
	end
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
