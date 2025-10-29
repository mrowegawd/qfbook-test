local PickerUtils = require "qfbookmark.pickers.utils"
local QfbookmarkUtils = require "qfbookmark.utils"

local M = {}

local function default_picker()
  return "default"
end

local silent_warn_notify = false

---@param picker_name string?
---@private
local function get_picker(picker_name)
  picker_name = picker_name or ""

  if PickerUtils.is_blank(picker_name) or silent_warn_notify then
    picker_name = default_picker()
  end

  local ok, picker = pcall(require, string.format("qfbookmark.pickers.%s", picker_name))

  if not ok then
    if not silent_warn_notify then
      QfbookmarkUtils.warn(
        string.format(
          "The picker `%s` has not been implemented yet.\nFalling back to the default `vim.ui.select`.",
          picker_name
        )
      )

      silent_warn_notify = true
    end

    return get_picker "default"
  end

  return picker
end

---@param config QFBookmarkConfig
---@private
function M.handle_state(config)
  local picker_name = config.picker
  local picker = get_picker(picker_name)
  -- RUtils.info(vim.inspect(picker))
  picker.set_state(config)
end

return M
