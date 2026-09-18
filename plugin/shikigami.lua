-- Eager registration so `:Shikigami` works without calling
-- `require("shikigami").setup()` (convention over configuration). setup() only
-- exists to change the defaults.
if vim.g.loaded_shikigami then
  return
end

-- `vim.fs.root` and `jobstart({ term = true })` are both 0.10 APIs, and the
-- plugin is nothing but those two calls — so refuse loudly instead of throwing
-- an obscure "attempt to call a nil value" at the first `:Shikigami`.
if vim.fn.has("nvim-0.10") == 0 then
  vim.notify("shikigami.nvim requires Neovim >= 0.10", vim.log.levels.ERROR, { title = "shikigami" })
  return
end

vim.g.loaded_shikigami = true

require("shikigami.command").register()
