<div align="center">

<h1>shikigami.nvim</h1>

<p><em>the jj TUI, one <code>:Shikigami</code> away.</em></p>

[![CI](https://github.com/yukimemi/shikigami.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/yukimemi/shikigami.nvim/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/yukimemi/shikigami.nvim/blob/main/LICENSE)
[![Neovim 0.10+](https://img.shields.io/badge/Neovim-0.10+-57A143?logo=neovim&logoColor=white)](https://neovim.io)

</div>

A thin front end for [shikigami](https://github.com/yukimemi/shikigami), the
ratatui TUI for [Jujutsu](https://github.com/jj-vcs/jj). The plugin finds the
jj repository, builds the command line and runs the binary in a Neovim
terminal — all of the UI lives in the binary, and when it exits your buffers
are reloaded from disk so the working copy jj just rewrote is what you see.

## Requirements

- Neovim >= 0.10
- [`shikigami`](https://github.com/yukimemi/shikigami) on `$PATH`
- [`jj`](https://github.com/jj-vcs/jj) on `$PATH` (the TUI drives it)

## Install

With [rvpm](https://github.com/yukimemi/rvpm) (recommended):

```sh
rvpm add yukimemi/shikigami.nvim --on-cmd Shikigami
```

Or in `config.toml`:

```toml
[[plugins]]
url = "https://github.com/yukimemi/shikigami.nvim"
on_cmd = ["Shikigami"]
```

> `setup()` is optional here: `plugin/shikigami.lua` registers `:Shikigami`
> eagerly, so the defaults work with no hook at all. Put
> `require("shikigami").setup({ ... })` in
> `plugins/github.com/yukimemi/shikigami.nvim/after.lua` only if you want to
> change them (`rvpm edit yukimemi/shikigami.nvim --after`).

Or with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "yukimemi/shikigami.nvim",
  cmd = "Shikigami",
  opts = {},
}
```

`opts` is passed straight to `require("shikigami").setup()`.

## Configuration

Defaults:

```lua
require("shikigami").setup({
  cmd = "shikigami",         -- string, or a list: { "cargo", "run", "--" }
  args = {},                 -- always appended to the command line
  revset = nil,              -- forwarded as `-r <revset>`
  repository = nil,          -- forwarded as `-R <path>`; nil = auto-detect
  auto_detect_root = true,   -- find the jj root from the current buffer
  auto_reload = true,        -- `:checktime` after the TUI exits
  close_on_exit = true,      -- close the window when the process exits 0
  terminal = {
    opener = "float",        -- "float"|"split"|"hsplit"|"vsplit"|"tabnew"|"tab"
                             -- any other string is run as an ex-command,
                             -- e.g. "botright 20split"; a function is called
                             -- and must leave the target window current
    width = 0.9,             -- float only: fraction of the UI
    height = 0.9,            -- float only: fraction of the UI
    border = "rounded",      -- float only
    title = true,            -- float only: show the argv as the title
  },
})
```

Unknown keys are an error naming the key, at both levels — `terminal.openner`
fails loudly instead of leaving you with an unexplained float.

Repository resolution looks for a `.jj` directory, walking up from the current
buffer and falling back to the cwd. Only `.jj` counts: a colocated repo has
`.git` as well, but a git-only repo has no jj log to show, so `:Shikigami`
says so instead of letting the binary fail with a confusing `-R` error. Set
`auto_detect_root = false` to let the binary resolve the repo itself.

A non-zero exit keeps the terminal window open, so the jj error text stays on
screen.

## Commands

| Command | Action |
| --- | --- |
| `:Shikigami` | Open the TUI for the current repository |
| `:Shikigami [args]` | Same, with arguments forwarded to the binary verbatim |

```vim
:Shikigami
:Shikigami -r 'all()'
:Shikigami -R ~/src/github.com/yukimemi/shikigami
:Shikigami --version
```

Completion offers the binary's top-level arguments (`-R`, `-r`, `--help`,
`--version`, `completion`), and the shell names after `completion`.

No keymaps, no default mappings: every key inside the window belongs to the
TUI, and the plugin starts in terminal mode so the first keypress reaches it
(`<C-\><C-n>` to leave). The terminal buffer is named `shikigami://…` with
`filetype=shikigami` if you want to hang your own mappings off it — see
`:h shikigami-terminal`.

## Lua API

```lua
local shikigami = require("shikigami")
shikigami.open()                        -- == :Shikigami
shikigami.open({ revset = "all()" })    -- per-call overrides
shikigami.version()                     -- `shikigami --version`, or nil
```

## Health

```vim
:checkhealth shikigami
```

## License

MIT
