local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local terminal = require("shikigami.terminal")
local config = require("shikigami.config")

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      config.setup()
      vim.cmd("silent! %bwipeout!")
    end,
  },
})

---Collect notifications instead of printing them, and return them.
---@param fn fun()
---@return { msg: string, level: integer }[]
local function capture_notify(fn)
  local original = vim.notify
  local seen = {}
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = msg, level = level }
  end
  local ok, e = pcall(fn)
  vim.notify = original
  assert(ok, e)
  return seen
end

T["opener shortcuts map to the window-creating ex-commands"] = function()
  eq(terminal.SHORTCUTS, {
    split = "new",
    hsplit = "new",
    vsplit = "vnew",
    tabnew = "tabnew",
    tab = "tabnew",
  })
end

T["an empty unnamed buffer is a reusable scratch"] = function()
  local buf = vim.api.nvim_create_buf(false, true)
  eq(terminal._buffer_is_empty_scratch(buf), true)
  -- A single empty line is what `:enew` leaves behind, not content.
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
  eq(terminal._buffer_is_empty_scratch(buf), true)
end

T["a buffer holding text or a name is not reusable"] = function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "work in progress" })
  eq(terminal._buffer_is_empty_scratch(buf), false)

  local named = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(named, vim.fs.normalize(vim.fn.tempname()) .. "/note.txt")
  eq(terminal._buffer_is_empty_scratch(named), false)
end

T["an unnamed buffer with unsaved edits is not reusable"] = function()
  -- `:enew` and then typing (and deleting it again) leaves an empty, unnamed
  -- but modified buffer: still the user's work, still off limits. A real
  -- buffer, not `nvim_create_buf(_, true)` — 'modified' cannot be set on a
  -- `nofile` scratch.
  local buf = vim.api.nvim_create_buf(true, false)
  vim.bo[buf].modified = true
  eq(terminal._buffer_is_empty_scratch(buf), false)
end

T["open refuses to clobber the current buffer when the opener does nothing"] = function()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "important" })
  config.setup({ terminal = { opener = function() end } })

  local jobid
  local notified = capture_notify(function()
    jobid = terminal.open({ "definitely-not-a-real-binary-xyz" })
  end)

  eq(jobid, nil)
  eq(#notified, 1)
  eq(notified[1].level, vim.log.levels.ERROR)
  eq(notified[1].msg:find("aborting", 1, true) ~= nil, true)
  -- Nothing touched the user's buffer.
  eq(vim.api.nvim_get_current_buf(), buf)
  eq(vim.bo[buf].buftype, "")
  eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "important" })
end

return T
