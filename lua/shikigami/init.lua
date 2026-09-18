local M = {}

---Configure the plugin. Optional: `:Shikigami` is registered eagerly by
---`plugin/shikigami.lua` and runs with the defaults, so `setup()` is only
---needed to change them.
---@param opts? shikigami.Options
function M.setup(opts)
  require("shikigami.config").setup(opts)
  require("shikigami.command").register()
end

---Resolve the repo to operate on: an explicit `repository` wins, otherwise the
---jj root of the current buffer when `auto_detect_root` is on.
---@param opts shikigami.ArgvOpts
---@return string|nil repository  nil = let the binary use its own cwd.
---@return string|nil err
local function resolve_repository(opts)
  local cfg = require("shikigami.config")
  local repository = opts.repository or cfg.options.repository
  if repository then
    return vim.fs.normalize(vim.fn.expand(repository)), nil
  end
  if not cfg.options.auto_detect_root then
    return nil, nil
  end
  local root = require("shikigami.cli").root(0)
  if not root then
    return nil, "not inside a jj repository (no `.jj` found above the current buffer or cwd)"
  end
  return vim.fs.normalize(root), nil
end

---Launch the TUI in a terminal window.
---@param opts? shikigami.ArgvOpts
---@return integer|nil jobid  nil when the launch was refused.
function M.open(opts)
  opts = opts or {}
  local cli = require("shikigami.cli")

  if not cli.executable() then
    local msg = "shikigami.nvim: `%s` not found in PATH — see https://github.com/yukimemi/shikigami"
    vim.notify(msg:format(cli.command()[1]), vim.log.levels.ERROR, { title = "shikigami" })
    return nil
  end

  local repository, err = resolve_repository(opts)
  if err then
    vim.notify("shikigami.nvim: " .. err, vim.log.levels.ERROR, { title = "shikigami" })
    return nil
  end

  local argv = cli.argv(vim.tbl_extend("force", opts, { repository = repository }))
  local label = "shikigami"
  if #(opts.extra or {}) > 0 then
    label = label .. " " .. table.concat(opts.extra, " ")
  end

  -- The TUI shells out to jj, which resolves the repo from its cwd unless
  -- `-R` is given; keeping both in sync avoids a mismatch when a user sets
  -- `repository` by hand.
  return require("shikigami.terminal").open(argv, { cwd = repository, title = label })
end

---`<cmd> --version` output, or nil when the binary is missing or errors.
---Used by `:checkhealth shikigami`; handy for a statusline / bug report too.
---@return string|nil
function M.version()
  local cli = require("shikigami.cli")
  if not cli.executable() then
    return nil
  end
  -- Deliberately not `cli.argv()`: the probe must not inherit `-R` / `-r` /
  -- `args`, which can make an otherwise fine binary exit non-zero.
  local argv = cli.command()
  argv[#argv + 1] = "--version"
  local result = vim.system(argv, { text = true }):wait(5000)
  if result.code ~= 0 then
    return nil
  end
  local out = vim.trim(result.stdout or "")
  return out ~= "" and out or nil
end

return M
