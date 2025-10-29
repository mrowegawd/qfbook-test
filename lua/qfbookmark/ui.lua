local Config = require("qfbookmark.config").defaults
local QfbookmarkUtils = require "qfbookmark.utils"

local loaded = false
local Event
local Input

local function setup_nui()
  if loaded then
    return Event, Input
  end

  local ok, _ = pcall(require, "nui.input")
  if not ok then
    QfbookmarkUtils.error "This extension requires `MunifTanjim/nui.nvim` (https://github.com/MunifTanjim/nui.nvim)"
    return
  end

  Event = require("nui.utils.autocmd").event
  Input = require "nui.input"
  loaded = true

  return Event, Input
end

setup_nui()

local M = {}

---@param fn function
---@param title_border string
---@private
function M.input(fn, title_border)
  if vim.bo.filetype == "qf" then
    vim.cmd.wincmd "p"
  end
  local input_opts = {
    position = "50%",
    relative = "editor",
    size = {
      width = 60,
      height = 20,
    },
    border = {
      style = "single",
      padding = { top = 1, bottom = 1, left = 1, right = 1 },
      text = {
        top = string.format(" %s %s ", Config.window.popup.icons.box_message, title_border),
        top_align = "center",
      },
    },
    win_options = { winhighlight = Config.window.popup.winhighlight },
  }

  local input = Input(input_opts, {
    prompt = "  ",
    on_submit = function(value)
      fn(value)
    end,
  })

  input:mount()

  -- unmount component when cursor leaves buffer
  input:on(Event.BufLeave, function()
    input:unmount()
  end)
  input:map("n", "<Esc>", function()
    input:unmount()
  end, { noremap = true })
  input:map("n", "<c-c>", function()
    input:unmount()
  end, { noremap = true })
  input:map("n", "q", function()
    input:unmount()
  end, { noremap = true })
end

return M
