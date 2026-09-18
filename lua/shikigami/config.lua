local M = {}

---@class shikigami.TerminalOpts
---@field opener string|fun()  How to create the host window for the TUI.
---                            Built-in shortcuts: "float" (default), "split",
---                            "hsplit", "vsplit", "tabnew", "tab". Any other
---                            string is passed to `vim.cmd()` as-is (e.g.
---                            "botright 20split"). A function is invoked and
---                            must leave the target window current.
---@field width number         Float-only: fraction of editor width (0..1).
---@field height number        Float-only: fraction of editor height (0..1).
---@field border string        Float-only: border style passed to nvim_open_win.
---@field title boolean        Float-only: draw the argv as the window title.

---@class shikigami.Options
---@field cmd string|string[]      The `shikigami` binary. A list lets you run it
---                                through another launcher, e.g. { "cargo", "run", "--" }.
---@field args string[]            Extra arguments appended to every invocation.
---@field revset string|nil        Initial revset, forwarded as `-r <revset>`.
---@field repository string|nil    Repo path, forwarded as `-R <path>`. Nil = auto-detect.
---@field auto_detect_root boolean Detect the jj root from the current buffer and pass `-R`.
---@field auto_reload boolean      `:checktime` after the TUI exits, so buffers jj rewrote reload.
---@field close_on_exit boolean    Close the terminal window when the process exits 0.
---@field terminal shikigami.TerminalOpts

M.defaults = {
  cmd = "shikigami",
  args = {},
  revset = nil,
  repository = nil,
  auto_detect_root = true,
  auto_reload = true,
  close_on_exit = true,
  terminal = {
    opener = "float",
    width = 0.9,
    height = 0.9,
    border = "rounded",
    title = true,
  },
}

---The key sets are spelled out instead of derived from `M.defaults`, because
---`revset` / `repository` default to nil and therefore do not exist as keys in
---the defaults table — deriving would reject exactly the two options users are
---most likely to set.
local KNOWN = {
  "cmd",
  "args",
  "revset",
  "repository",
  "auto_detect_root",
  "auto_reload",
  "close_on_exit",
  "terminal",
}

local KNOWN_TERMINAL = { "opener", "width", "height", "border", "title" }

M.options = vim.deepcopy(M.defaults)

---@param keys string[]
---@return table<string, true>
local function set_of(keys)
  local set = {}
  for _, key in ipairs(keys) do
    set[key] = true
  end
  return set
end

---A typo must be loud. `terminal = { openner = "split" }` silently merges into
---the defaults and leaves the user staring at a float wondering why their
---setting does nothing, so unknown keys are a hard error naming the key and
---the accepted set.
---@param tbl table
---@param keys string[]
---@param where string  Prefix used in the message ("" for the top level).
local function reject_unknown(tbl, keys, where)
  local known = set_of(keys)
  for key in pairs(tbl) do
    if not known[key] then
      error(
        ("shikigami.nvim: unknown option `%s%s` (known: %s)"):format(where, tostring(key), table.concat(keys, ", ")),
        0
      )
    end
  end
end

---@param opts table
local function validate(opts)
  reject_unknown(opts, KNOWN, "")
  vim.validate({
    cmd = { opts.cmd, { "string", "table" }, true },
    args = { opts.args, "table", true },
    revset = { opts.revset, "string", true },
    repository = { opts.repository, "string", true },
    auto_detect_root = { opts.auto_detect_root, "boolean", true },
    auto_reload = { opts.auto_reload, "boolean", true },
    close_on_exit = { opts.close_on_exit, "boolean", true },
    terminal = { opts.terminal, "table", true },
  })

  local terminal = opts.terminal
  if terminal == nil then
    return
  end
  reject_unknown(terminal, KNOWN_TERMINAL, "terminal.")
  vim.validate({
    ["terminal.opener"] = { terminal.opener, { "string", "function" }, true },
    ["terminal.width"] = { terminal.width, "number", true },
    ["terminal.height"] = { terminal.height, "number", true },
    ["terminal.border"] = { terminal.border, { "string", "table" }, true },
    ["terminal.title"] = { terminal.title, "boolean", true },
  })
end

---Merge `opts` over the defaults. `args` and `cmd` are lists, and
---`tbl_deep_extend` merges lists by index, so a user `cmd = { "cargo", "run" }`
---would inherit leftover elements from a longer default. Both currently have a
---short/empty default, but the explicit overwrite keeps that an accident we
---cannot have.
---@param opts? shikigami.Options
function M.setup(opts)
  opts = opts or {}
  validate(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
  if opts.cmd ~= nil then
    M.options.cmd = vim.deepcopy(opts.cmd)
  end
  if opts.args ~= nil then
    M.options.args = vim.deepcopy(opts.args)
  end
end

return M
