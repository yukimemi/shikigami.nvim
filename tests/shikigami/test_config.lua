local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local err = MiniTest.expect.error

local config = require("shikigami.config")

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      config.setup()
    end,
  },
})

T["an unknown top-level key is rejected by name"] = function()
  err(function()
    config.setup({ openner = "split" })
  end, "unknown option `openner`")
  err(function()
    config.setup({ auto_reloads = true })
  end, "unknown option `auto_reloads`")
end

T["an unknown terminal key is rejected by its dotted name"] = function()
  err(function()
    config.setup({ terminal = { openner = "split" } })
  end, "unknown option `terminal%.openner`")
end

T["a rejected setup leaves the previous options in place"] = function()
  config.setup({ revset = "@" })
  pcall(config.setup, { terminal = { openner = "split" } })
  eq(config.options.revset, "@")
  eq(config.options.terminal.opener, "float")
end

T["terminal.opener must be a string or a function"] = function()
  err(function()
    config.setup({ terminal = { opener = 42 } })
  end, "opener")
  err(function()
    config.setup({ terminal = { opener = { "vnew" } } })
  end, "opener")
  config.setup({ terminal = { opener = function() end } })
  eq(type(config.options.terminal.opener), "function")
  config.setup({ terminal = { opener = "botright 20split" } })
  eq(config.options.terminal.opener, "botright 20split")
end

T["cmd takes a string or a list, nothing else"] = function()
  err(function()
    config.setup({ cmd = 1 })
  end, "cmd")
  err(function()
    config.setup({ revset = 1 })
  end, "revset")
  err(function()
    config.setup({ close_on_exit = "yes" })
  end, "close_on_exit")
end

T["a partial terminal table keeps its sibling defaults"] = function()
  config.setup({ terminal = { opener = "vsplit" } })
  eq(config.options.terminal.opener, "vsplit")
  eq(config.options.terminal.width, 0.9)
  eq(config.options.terminal.border, "rounded")
  eq(config.options.auto_reload, true)
end

T["a user cmd list replaces the default instead of merging into it"] = function()
  -- `tbl_deep_extend` merges lists by index; a shorter user list would keep
  -- the tail of the default one. `{ "cargo", "run" }` must not become
  -- `{ "cargo", "run" }` plus leftovers, and `args = {}` must clear.
  config.setup({ cmd = { "cargo", "run", "--" }, args = { "--one" } })
  eq(config.options.cmd, { "cargo", "run", "--" })
  config.setup({ cmd = "shikigami" })
  eq(config.options.cmd, "shikigami")
  eq(config.options.args, {})
end

T["setup leaves the defaults table untouched"] = function()
  config.setup({ terminal = { opener = "vsplit" }, args = { "--x" } })
  eq(config.defaults.terminal.opener, "float")
  eq(config.defaults.args, {})
end

return T
