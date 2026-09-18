local M = {}

---Top-level arguments of the `shikigami` CLI, mirrored from `shikigami --help`.
---Public and documented (|shikigami-commands|): completion and the docs read
---this one table, so a CLI change is a one-line update here.
M.ARGUMENTS = {
  "-R",
  "--repository",
  "-r",
  "--revisions",
  "-h",
  "--help",
  "-V",
  "--version",
  "completion",
}

---`shikigami completion <SHELL>` — clap_complete's supported shell set.
M.SHELLS = { "bash", "zsh", "fish", "powershell", "elvish" }

---@param items string[]
---@param prefix string
---@return string[]
local function filter_prefix(items, prefix)
  return vim.tbl_filter(function(s)
    return s:sub(1, #prefix) == prefix
  end, items)
end

---@param arg_lead string
---@param cmd_line string
---@return string[]
local function complete(arg_lead, cmd_line, _cursor_pos)
  local parts = vim.split(vim.trim(cmd_line), "%s+")
  local has_trailing_space = cmd_line:match("%s$") ~= nil
  local position = #parts + (has_trailing_space and 1 or 0)

  -- `:Shikigami completion <Tab>` → the shell names, not the flags again.
  if position > 2 and parts[2] == "completion" then
    return filter_prefix(M.SHELLS, arg_lead)
  end

  return filter_prefix(M.ARGUMENTS, arg_lead)
end

---Register `:Shikigami`. Safe to call more than once.
function M.register()
  vim.api.nvim_create_user_command("Shikigami", function(opts)
    -- fargs, not the raw line: nvim has already done the shell-ish splitting
    -- and quote handling, and jobstart takes a list (no second shell parse).
    require("shikigami").open({ extra = opts.fargs })
  end, {
    nargs = "*",
    complete = complete,
    desc = "Open the shikigami jj TUI in a terminal window",
  })
end

return M
