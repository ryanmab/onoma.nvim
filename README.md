[![Build](https://github.com/ryanmab/onoma.nvim/actions/workflows/build.yml/badge.svg)](https://github.com/ryanmab/onoma.nvim/actions/workflows/build.yml)
![GitHub License](https://img.shields.io/github/license/ryanmab/onoma.nvim)

> [!WARNING]
> Onoma and all of its editor integrations are still in early development. Expect bugs, breaking changes, and other
> general hiccups.

# Onoma.nvim

> **ὄνομα** — *Onoma* (pronounced `OH-no-ma`) is Greek for **“name”**, signifying not just a
> label, but the *essence* or character of a thing.

Onoma.nvim is a Neovim plugin built around [Onoma](https://github.com/ryanmab/onoma), the fast, language-agnostic
semantic symbol indexer and fuzzy finder, which doesn't require a full language server or limit workspace-wide searches.

It provides a first-class integration into Neovim, using Snacks Picker or Telescope as the frontend for fuzzy finding semantic symbols in source code.

## Supported Languages

- Rust (`.rs`)
- Go (`.go`)
- Lua (`.lua`)
- Clojure (`.clj`)
- TypeScript (`.ts` and `.tsx`) / JavaScript (`.js` and `.jsx`)
- Python (`.py`)

## Demo

https://github.com/user-attachments/assets/e5e90738-6976-4951-9a2f-4cad7f3ba1c3

## Installation

### Lazy.nvim

<details>

<summary>Snacks</summary>

```lua
return {
	'ryanmab/onoma.nvim',

	version = '*', -- Required for stable releases (recommended)

	-- Or, you can use the nightly builds
	-- tag = 'nightly',

	-- Otherwise, you can build from source
	-- build = 'cargo --config ./bridge/.cargo/config.toml build --release --manifest-path ./bridge/Cargo.toml'

	dependencies = {
		'folke/snacks.nvim',
	},
	event = 'VeryLazy',
	config = function()
		require('onoma').setup({
			-- Default configuration can be found in: "lua/config.lua"
			picker = { 'snacks' },
		})

		vim.keymap.set({ 'n', 'v', 'x' }, 'fs', Snacks.picker.get_symbols, { desc = 'Symbols', silent = true })
	end,
}
```

</details>

<details>

<summary>Telescope</summary>

```lua
return {
	'ryanmab/onoma.nvim',

	version = '*', -- Required for stable releases (recommended)

	-- Or, you can use the nightly builds
	-- tag = 'nightly',

	-- Otherwise, you can build from source
	-- build = 'cargo --config ./bridge/.cargo/config.toml build --release --manifest-path ./bridge/Cargo.toml'

	dependencies = {
		'nvim-telescope/telescope.nvim',
	},
	event = 'VeryLazy',
	config = function()
		require('onoma').setup({
			-- Default configuration can be found in: "lua/config.lua"
			picker = { 'telescope' },
		})

		vim.keymap.set(
			{ 'n', 'v', 'x' },
			'fs',
			require('telescope').extensions.onoma.get_symbols,
			{ desc = 'Symbols', silent = true }
		)
	end,
}
```

</details>

<details>

<summary>Mini.Pick</summary>

```lua
return {
	'ryanmab/onoma.nvim',

	version = '*', -- Required for stable releases (recommended)

	-- Or, you can use the nightly builds
	-- tag = 'nightly',

	-- Otherwise, you can build from source
	-- build = 'cargo --config ./bridge/.cargo/config.toml build --release --manifest-path ./bridge/Cargo.toml'

	dependencies = {
		{ 'nvim-mini/mini.pick', version = '*' },
	},
	event = 'VeryLazy',
	config = function()
		require('onoma').setup({
			-- Default configuration can be found in: "lua/config.lua"
			picker = { 'mini' },
		})

		vim.keymap.set({ 'n', 'v', 'x' }, 'fs', MiniPick.registry.get_symbols, { desc = 'Symbols', silent = true })
	end,
}
```

</details>

### vim.pack

<details>

<summary>Snacks</summary>

```lua
vim.api.nvim_create_autocmd('PackChanged', {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind

		if name == 'onoma.nvim' and (kind == 'install' or kind == 'update') then
			if not ev.data.active then
				vim.cmd.packadd('onoma.nvim')
			end

			require('onoma').build():await()
		end
	end,
})

vim.pack.add({
	'folke/snacks.nvim',
	{
		src = 'https://github.com/ryanmab/onoma.nvim',

		version = '*', -- Required for stable releases (recommended)

		-- Or, you can use the nightly builds
		-- tag = 'nightly',
	},
})

require('onoma').setup({
	-- Default configuration can be found in: "lua/config.lua"
	picker = { 'snacks' },
})

vim.keymap.set({ 'n', 'v', 'x' }, 'fs', Snacks.picker.get_symbols, {
	desc = 'Symbols',
	silent = true,
})
```

</details>

<details>

<summary>Telescope</summary>

```lua
vim.api.nvim_create_autocmd('PackChanged', {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind

		if name == 'onoma.nvim' and (kind == 'install' or kind == 'update') then
			if not ev.data.active then
				vim.cmd.packadd('onoma.nvim')
			end

			require('onoma').build():await()
		end
	end,
})

vim.pack.add({
	'nvim-telescope/telescope.nvim',
	{
		src = 'https://github.com/ryanmab/onoma.nvim',

		version = '*', -- Required for stable releases (recommended)

		-- Or, you can use the nightly builds
		-- tag = 'nightly',
	},
})

require('onoma').setup({
	-- Default configuration can be found in: "lua/config.lua"
	picker = { 'telescope' },
})

vim.keymap.set(
	{ 'n', 'v', 'x' },
	'fs',
	require('telescope').extensions.onoma.get_symbols,
	{ desc = 'Symbols', silent = true }
)
```

</details>

<details>

<summary>Mini.Pick</summary>

```lua
vim.api.nvim_create_autocmd('PackChanged', {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind

		if name == 'onoma.nvim' and (kind == 'install' or kind == 'update') then
			if not ev.data.active then
				vim.cmd.packadd('onoma.nvim')
			end

			require('onoma').build():await()
		end
	end,
})

vim.pack.add({
	{ 'nvim-mini/mini.pick', version = '*' },
	{
		src = 'https://github.com/ryanmab/onoma.nvim',

		version = '*', -- Required for stable releases (recommended)

		-- Or, you can use the nightly builds
		-- tag = 'nightly',
	},
})

require('onoma').setup({
	-- Default configuration can be found in: "lua/config.lua"
	picker = { 'mini' },
})

vim.keymap.set({ 'n', 'v', 'x' }, 'fs', MiniPick.registry.get_symbols, { desc = 'Symbols', silent = true })
```

</details>

## Contributing

Contributions are welcome!

The [core Onoma backend](https://github.com/ryanmab/onoma) contains all editor-agnostic functionality,
including improvements to indexing and fuzzy matching.

For editor-specific features or changes to bindings for a particular editor, please submit pull requests
in the respective editor repositories.

## Acknowledgments

- [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim/tree/main) for inspiring the semantic fuzzy finder design in Onoma.
- [snacks.nvim](https://github.com/folke/snacks.nvim/tree/main) for the excellent picker frontend.
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for the excellent picker frontend.
- [frizbee](https://github.com/saghen/frizbee) for the high-performance SIMD implementation of fuzzy matching.
