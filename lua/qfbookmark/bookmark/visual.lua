local M = { sign_cache = {} }
local Config = require("qfbookmark.config").defaults

---@param id number
---@param bufnr number
---@param line number
---@param text string
---@param extmarkspec QFBookSpec
---@private
function M.insert_signs(id, bufnr, line, text, extmarkspec)
  local sign_name = "QfbookmarkMark" .. text

  if not M.sign_cache[sign_name] then
    M.sign_cache[sign_name] = true
    if Config.extmarks.enabled then
      vim.fn.sign_define(sign_name, { text = extmarkspec.icon, texthl = extmarkspec.hl_group })
    end
  end

  local priority = 1
  if Config.extmarks.priority then
    priority = Config.extmarks.priority
  end

  vim.fn.sign_place(id, extmarkspec.hl_group, sign_name, bufnr, { lnum = line, priority = priority })
end

return M
