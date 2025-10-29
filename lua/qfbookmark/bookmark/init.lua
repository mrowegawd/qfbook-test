local Config = require("qfbookmark.config").defaults
local QfbookmarkUtils = require "qfbookmark.utils"
local QfbookmarkMarkUtils = require "qfbookmark.bookmark.utils"
local QfbookmarkMarkVisual = require "qfbookmark.bookmark.visual"

local M = {
  extmarks_name = "QfbookmarkMark",
  ns = 0,
}

M.buffers = {}

---@private
function M.delete_line_marks()
  QfbookmarkUtils.not_implemented_yet()
end

---@param buf integer
---@private
function M.update_render_extermark(buf)
  if M.ns > 0 then
    -- Clear dahulu extemarks, sebelum di render di quickfix window
    -- untuk mencegah duplikasi ketika `delete item` atau `update item`
    vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  end
end

local autocmds_set = false

---@param force_set? boolean
local function setup_autocmds(force_set)
  force_set = force_set or false

  if autocmds_set and not force_set then
    return
  end

  autocmds_set = true

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function(args)
      local qf_buf = args.buf

      M.ns = vim.api.nvim_create_namespace(M.extmarks_name .. "Au")

      -- Clear dahulu extemarks, sebelum di render di quickfix window
      -- untuk mencegah duplikasi ketika `delete item` atau `update item`
      M.update_render_extermark(qf_buf)

      local lines = vim.api.nvim_buf_get_lines(qf_buf, 0, -1, false)
      for i, line in ipairs(lines) do
        local keywords_pattern = Config.extmarks.keywords ---@type QFBookKeywords
        for _, key in pairs(keywords_pattern) do
          if line:find(key.alt, 1, true) then
            vim.api.nvim_buf_set_extmark(qf_buf, M.ns, i - 1, 0, {
              virt_text = { { key.icon .. " ", "WarningMsg" } },
              virt_text_pos = "inline",
            })
          end
        end
      end
    end,
  })
end

---@param line integer
---@param text string
---@param extmarkspec QFBookSpec
---@private
function M.place_next_mark(line, text, extmarkspec)
  local bufnr = vim.api.nvim_get_current_buf()
  local id = tonumber(line .. bufnr)
  if id then
    QfbookmarkUtils.info(tostring(id))
    QfbookmarkMarkVisual.insert_signs(id, bufnr, line, text, extmarkspec)
    setup_autocmds()
  end
end

---@param extmarkspec QFBookSpec
---@private
function M.add_extmark(extmarkspec)
  if not Config.extmarks.enabled then
    return
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local text = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)[1]

  if QfbookmarkMarkUtils.is_current_line_got_mark(M.buffers, pos[1]) then
    M.delete_line_marks()
  else
    M.place_next_mark(pos[1], text, extmarkspec)
  end
end

return M
