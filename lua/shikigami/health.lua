local M = {}

local h = vim.health
local start = h.start or h.report_start
local ok = h.ok or h.report_ok
local info = h.info or h.report_info
local warn = h.warn or h.report_warn
local error_ = h.error or h.report_error

---First line of `<argv> --version`, or nil when it cannot be run.
---@param argv string[]
---@return string|nil
local function version_of(argv)
  local result = vim.system(argv, { text = true }):wait(5000)
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(vim.split(result.stdout or "", "\n", { plain = true })[1] or "")
end

function M.check()
  start("shikigami.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    ok("Neovim >= 0.10")
  else
    error_("Neovim 0.10+ required (vim.fs.root, jobstart term=true)")
  end

  local cli = require("shikigami.cli")
  local options = require("shikigami.config").options
  local bin = cli.command()[1]

  if cli.executable() then
    ok("shikigami binary: " .. vim.fn.exepath(bin))
    local version = require("shikigami").version()
    if version then
      ok("shikigami --version: " .. version)
    else
      warn(("`%s --version` failed — the binary is on PATH but not runnable"):format(bin))
    end
  else
    local msg = "shikigami not found in PATH (looked for: %s) — install from https://github.com/yukimemi/shikigami"
    error_(msg:format(bin))
  end

  -- The TUI is a front end for jj; without the jj binary it has nothing to
  -- drive, so this is an error and not a warning.
  if vim.fn.executable("jj") == 1 then
    local version = version_of({ "jj", "--version" })
    ok("jj: " .. (version or vim.fn.exepath("jj")))
  else
    error_("jj not found in PATH — shikigami drives jj and cannot work without it")
  end

  local root = cli.root(0)
  if root then
    ok("jj repository: " .. root)
  else
    warn("cwd is not inside a jj repository (no `.jj` found) — `:Shikigami` will refuse to start here")
  end

  info("cmd: " .. vim.inspect(options.cmd))
  info("args: " .. vim.inspect(options.args))
  info(
    ("repository: %s (auto_detect_root: %s)"):format(tostring(options.repository), tostring(options.auto_detect_root))
  )
  info("revset: " .. tostring(options.revset))
  info(("auto_reload: %s, close_on_exit: %s"):format(tostring(options.auto_reload), tostring(options.close_on_exit)))
  info("terminal: " .. vim.inspect(options.terminal, { newline = " ", indent = "" }))
end

return M
