require('onoma')
	.build()
	-- Pass messages back to the Lazy.nvim build coroutine, so that
	-- they'll appear in the UI
	:on_yield(
		coroutine.yield
	)
	:await()
