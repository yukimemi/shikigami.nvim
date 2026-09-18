local M = {}

local cfg = require("shikigami.config")

---The `cmd` option as a list, always a fresh copy so callers can append to it.
---Shared by `argv()`, the `--version` probe and health, so "how do we actually
---invoke the binary" is decided in exactly one place.
---@return string[]
function M.command()
  local cmd = cfg.options.cmd
  if type(cmd) == "table" then
    return vim.deepcopy(cmd)
  end
  return { cmd }
end

---@class shikigami.ArgvOpts
---@field repository? string  Overrides `options.repository` / the detected root.
---@field revset? string      Overrides `options.revset`.
---@field args? string[]      Overrides `options.args`.
---@field extra? string[]     Raw arguments from `:Shikigami`, appended last.

---Build the full argv for one invocation.
---
---The order is a contract, not an implementation detail: the plugin's own
---flags come first so anything the user types after `:Shikigami` wins when the
---CLI sees the same flag twice (clap keeps the last occurrence). That is what
---makes `:Shikigami -r 'all()'` able to override a configured `revset`.
---@param opts? shikigami.ArgvOpts
---@return string[]
function M.argv(opts)
  opts = opts or {}
  local argv = M.command()

  local repository = opts.repository or cfg.options.repository
  if repository then
    vim.list_extend(argv, { "-R", repository })
  end

  local revset = opts.revset or cfg.options.revset
  if revset then
    vim.list_extend(argv, { "-r", revset })
  end

  vim.list_extend(argv, opts.args or cfg.options.args or {})
  vim.list_extend(argv, opts.extra or {})

  return argv
end

---Whether the configured binary can be run. Only the first element of a list
---`cmd` is a program — `{ "cargo", "run", "--" }` is executable when `cargo` is.
---@return boolean
function M.executable()
  return vim.fn.executable(M.command()[1]) == 1
end

---The jj root for `bufnr`, found by walking up from the buffer's file.
---
---`.jj` is the only marker. A colocated repo has both `.jj/` and `.git/`, so
---looking for `.git` as a fallback would "succeed" inside a git-only repo —
---and then `shikigami -R <git-only-path>` fails with a jj error the user
---cannot act on. Nil here lets the caller say "not a jj repo" instead.
---@param bufnr? integer  Defaults to the current buffer.
---@return string|nil
function M.root(bufnr)
  bufnr = bufnr or 0
  -- An unnamed/scratch buffer has no path to walk up from (`:Shikigami` from a
  -- dashboard, a fresh `nvim`), so fall back to the editor's cwd.
  if vim.api.nvim_buf_get_name(bufnr) == "" then
    return vim.fs.root(assert(vim.uv.cwd()), ".jj")
  end
  return vim.fs.root(bufnr, ".jj")
end

return M
