local QfbookmarkUtils = require "qfbookmark.utils"

local M = {}

---@param tbl_cmdline_strings QFBookKeymapCMDLineStrings
---@private
function M.handle_mappings(tbl_cmdline_strings)
  local cmdline_strs = tbl_cmdline_strings.commands
  if vim.tbl_isempty(cmdline_strs) then
    return
  end

  for _, val in pairs(cmdline_strs) do
    if not val.mode then
      val.mode = "n"
    end
    local keymap_func
    if type(val.cmd) == "function" then
      keymap_func = function()
        local results
        if QfbookmarkUtils.is_loclist() then
          local data = QfbookmarkUtils.get_data_qf(true)
          results = data.location
        else
          local data = QfbookmarkUtils.get_data_qf()
          results = data.quickfix
        end

        if not vim.tbl_isempty(results.items) then
          local qflist_stack_idx = QfbookmarkUtils.get_current_qf_idx()
          ---@diagnostic disable-next-line: inject-field
          results.stack_idx = qflist_stack_idx
        end

        val.cmd(results)
      end
    elseif type(val.cmd) == "string" then
      keymap_func = function()
        local cmd = ":" .. val.cmd
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", false)
      end
    end

    val.desc = val.desc .. " [QFbookmark integration]"

    vim.keymap.set(val.mode, val.key, keymap_func, { silent = true, desc = val.desc })
  end
end

return M
