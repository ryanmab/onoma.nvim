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

It provides a first-class integration into Neovim, using Snacks Picker as the frontend for fuzzy finding semantic symbols in source code.

## Supported Languages

- Rust (`.rs`)
- Go (`.go`)
- Lua (`.lua`)
- Clojure (`.clj`)
- TypeScript (`.ts` and `.tsx`) / JavaScript (`.js` and `.jsx`)

## Demo

https://github.com/user-attachments/assets/6df459ec-e97d-4b95-8a97-11fb7aacecaf

## Installation

### Lazy.nvim

```lua
return {
     'ryanmab/onoma.nvim',

     version = '*', -- Required when using prebuilt binaries

     -- Otherwise, you can build from source (using Rust nightly)
     -- build = 'cargo --config ./bridge/.cargo/config.toml build --release --manifest-path ./bridge/Cargo.toml'

     dependencies = {
          'folke/snacks.nvim', -- Required if using the Onoma source for Snacks Picker
     },
     event = 'VeryLazy',
     config = function()
          require('onoma').setup({
               -- Default configuration can be found in: "lua/config.lua"
          })

          vim.keymap.set(
               { 'n', 'v', 'x' },
               'fs',
               function() Snacks.picker.onoma({}) end,
               { desc = 'Symbols', silent = true }
          )
     end,
}
```

## Contributing

Contributions are welcome!

The [core Onoma backend](https://github.com/ryanmab/onoma) contains all editor-agnostic functionality,
including improvements to indexing and fuzzy matching.

For editor-specific features or changes to bindings for a particular editor, please submit pull requests
in the respective editor repositories.

## Acknowledgments

- [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim/tree/main) for inspiring the semantic fuzzy finder design in Onoma.
- [snacks.nvim](https://github.com/folke/snacks.nvim/tree/main) for the excellent picker frontend.
- [frizbee](https://github.com/saghen/frizbee) for the high-performance SIMD implementation of fuzzy matching.
