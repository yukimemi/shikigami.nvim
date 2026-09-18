local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local cli = require("shikigami.cli")
local config = require("shikigami.config")

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      config.setup()
    end,
  },
})

---A throwaway directory tree; `children` are created as directories.
---
---The result is run through `fs_realpath`: on macOS `vim.fn.tempname()`
---hands back a path under `/var`, which is a symlink to `/private/var`,
---while `vim.fs.root()` reports the resolved location. Comparing the raw
---names fails on macOS only — and the difference says nothing about the
---behaviour under test.
---@param children string[]
---@return string
local function tmpdir(children)
  local dir = vim.fs.normalize(vim.fn.tempname())
  for _, child in ipairs(children) do
    vim.fn.mkdir(dir .. "/" .. child, "p")
  end
  return vim.fs.normalize(vim.uv.fs_realpath(dir) or dir)
end

T["argv order: cmd, -R, -r, args, then the command line"] = function()
  config.setup({
    cmd = "shikigami",
    args = { "--from-config" },
    repository = "/repo",
    revset = "@",
  })
  eq(cli.argv({ extra = { "-r", "all()" } }), {
    "shikigami",
    "-R",
    "/repo",
    "-r",
    "@",
    "--from-config",
    "-r",
    "all()",
  })
end

T["a list cmd is expanded ahead of every flag"] = function()
  config.setup({ cmd = { "cargo", "run", "--" }, revset = "trunk()" })
  eq(cli.argv(), { "cargo", "run", "--", "-r", "trunk()" })
end

T["unset repository / revset inject nothing"] = function()
  config.setup({ args = { "--tail" } })
  eq(cli.argv({ extra = { "--version" } }), { "shikigami", "--tail", "--version" })
end

T["per-call opts override the configured values"] = function()
  config.setup({ args = { "--from-config" }, repository = "/from-config", revset = "@" })
  eq(cli.argv({ repository = "/per-call", revset = "root()", args = { "--per-call" } }), {
    "shikigami",
    "-R",
    "/per-call",
    "-r",
    "root()",
    "--per-call",
  })
end

T["argv never hands out the configured tables"] = function()
  config.setup({ cmd = { "cargo", "run" }, args = { "--tail" } })
  local argv = cli.argv()
  argv[#argv + 1] = "mutated"
  eq(config.options.cmd, { "cargo", "run" })
  eq(config.options.args, { "--tail" })
  eq(cli.argv(), { "cargo", "run", "--tail" })
end

T["executable() tests the launcher, not the trailing arguments"] = function()
  config.setup({ cmd = { "definitely-not-a-real-binary-xyz", "run", "--" } })
  eq(cli.executable(), false)
  -- nvim is guaranteed to be on PATH inside a test run.
  config.setup({ cmd = { "nvim", "--headless" } })
  eq(cli.executable(), true)
end

T["root walks up from the buffer's file to the .jj directory"] = function()
  local root = tmpdir({ ".jj", "a/b" })
  local file = root .. "/a/b/file.txt"
  vim.fn.writefile({ "x" }, file)
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(buf)
  eq(vim.fs.normalize(cli.root(buf) or ""), root)
end

T["root ignores a git-only repository"] = function()
  local root = tmpdir({ ".git", "src" })
  local file = root .. "/src/file.txt"
  vim.fn.writefile({ "x" }, file)
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(buf)
  eq(cli.root(buf), nil)
end

T["root falls back to cwd for an unnamed buffer"] = function()
  local root = tmpdir({ ".jj", "a" })
  local cwd = vim.fn.getcwd()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.cmd.lcd(root .. "/a")
  local detected = cli.root(buf)
  vim.cmd.lcd(cwd)
  eq(vim.fs.normalize(detected or ""), root)
end

return T
