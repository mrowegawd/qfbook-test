local Config = require("qfbookmark.config").defaults
local QfbookmarkWindow = require "qfbookmark.window"
local QfbookmarkNav = require "qfbookmark.nav"
local QfbookmarkUtils = require "qfbookmark.utils"
local QfbookmarkBookmark = require "qfbookmark.bookmark"
local QfbookmarkUI = require "qfbookmark.ui"

local M = {}

local last_winid = 0

---@private
function M.delete_item()
  local curqfidx = vim.fn.line "."

  local data_lists = {}
  data_lists = QfbookmarkUtils.get_list_qf()

  local close_cmd = QfbookmarkUtils.is_loclist() and "lclose" or "cclose"
  local open_cmd = QfbookmarkUtils.is_loclist() and Config.window.layout.lopen or Config.window.layout.copen

  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  if count > #data_lists then
    count = #data_lists
  end

  local item = vim.api.nvim_win_get_cursor(0)[1]
  for _ = item, item + count - 1 do
    table.remove(data_lists, item)
  end

  if #data_lists ~= 0 then
    local title = QfbookmarkUtils.get_title_qf(QfbookmarkUtils.is_loclist())

    ---@type QFBookLists
    local list_items = {
      items = data_lists,
      title = title,
    }
    QfbookmarkUtils.save_to_qf(list_items, QfbookmarkUtils.is_loclist())

    if QfbookmarkUtils.is_loclist() then
      vim.cmd(string.format("%slfirst", curqfidx))
    else
      vim.cmd(string.format("%scfirst", curqfidx))
    end

    vim.schedule(function()
      vim.cmd(open_cmd)
    end)
  elseif #data_lists == 0 then
    vim.api.nvim_command(close_cmd)
  end

  if Config.extmarks.enabled then
    QfbookmarkBookmark.update_render_extermark(vim.api.nvim_get_current_buf())
  end
end

local clear_qf_list = function()
  QfbookmarkUtils.info("✅ The item list has been cleared", "QF")
  vim.fn.setqflist {}
  vim.cmd.cclose()
end
local clear_loc_list = function()
  QfbookmarkUtils.info("✅ The item list has been cleared", "LF")
  vim.fn.setloclist(0, {}, "r")
  vim.cmd.lclose()
end

---@private
function M.delete_all_items()
  if QfbookmarkUtils.is_loclist() then
    clear_loc_list()
  else
    clear_qf_list()
  end
end

---@param list_type QFBookListType
local rename_title = function(list_type)
  local is_location_target = list_type == "loclist"
  local cmd = is_location_target and { Config.window.layout.lopen, "LocList" }
    or { Config.window.layout.copen, "QuickFix" }

  if QfbookmarkUtils.is_loclist() then
    QfbookmarkUtils.warn("Renaming the title is not supported in the " .. cmd[2] .. ",\nOnly in Quickfix", cmd[2])
    return
  end

  QfbookmarkUI.input(function(input_msg)
    if input_msg == "" or input_msg == nil then
      return
    end
    vim.fn.setqflist({}, "r", { title = input_msg })
    vim.cmd(cmd[1])
  end, "Rename " .. cmd[2] .. " Title")
end
---@private
function M.rename_title()
  if QfbookmarkUtils.is_loclist() then
    rename_title "loclist"
    return
  end
  rename_title "quickfix"
end

---@private
function M.save_or_load()
  require("qfbookmark.pickers").handle_state(Config)
end

---@return boolean, QFBookListType
---@private
local is_vim_list_open = function()
  local curbuf = vim.api.nvim_get_current_buf()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if curbuf == buf then
      if QfbookmarkUtils.is_loclist(win) then
        return true, "loclist"
      end
      if vim.bo[buf].filetype == "qf" then
        return true, "quickfix"
      end
    end
  end
  return false, "none"
end

---@param list_type QFBookListType
---@param extmarkspec QFBookSpec
---@private
local add_item_and_mark = function(list_type, extmarkspec)
  if vim.bo.filetype == "qf" then
    return QfbookmarkUtils.warn "Operation is not allowed inside the quickfix window"
  end

  local is_location_target = list_type == "loclist"
  local cmd_ = is_location_target and { "lclose", Config.window.layout.lopen, "loclist" }
    or { "cclose", Config.window.layout.copen, "qflist" }

  local title = QfbookmarkUtils.get_title_qf(QfbookmarkUtils.is_loclist())
  if title and title:match "setqflist" or #title == 0 then
    title = "Add item into " .. (is_location_target and "lf" or "qf")
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local lnum = pos[1]
  local col = pos[2]

  ---@type QFBookLists
  local list_items = {
    items = {
      {
        bufnr = vim.api.nvim_get_current_buf(),
        lnum = lnum,
        col = col,
        text = extmarkspec.alt .. QfbookmarkUtils.strip_whitespace(vim.api.nvim_get_current_line()),
        line = vim.api.nvim_get_current_line(),
      },
    },
    title = title,
  }

  if is_location_target then
    QfbookmarkUtils.save_to_qf(list_items, true, "a")
  else
    QfbookmarkUtils.save_to_qf(list_items, false, "a")
  end

  if Config.extmarks.enabled then
    QfbookmarkBookmark.add_extmark(extmarkspec)
  end

  -- TODO: apakah perlu line code ini?
  -- karena terlalu annoying pesan nya
  -- if Config.window.notify.plugin then
  --   QfbookmarkUtils.info(string.format("✅ Add %s -> %s", cmd_[3], vim.api.nvim_get_current_line()))
  -- end

  if Config.window.popup.mark then
    local is_open, _ = is_vim_list_open()
    if not is_open then
      vim.cmd(cmd_[2])
      vim.cmd "wincmd p"
    end
  end
end

---@param list_type QFBookListType
---@param mode "MARK" | "DEBUG" | "NOTE" | "FIX"
---@private
local function add_item_with_mode(list_type, mode)
  local keyword = Config.extmarks.keywords[mode]
  add_item_and_mark(list_type, keyword)
end

---@private
function M.add_item_mark_qf()
  add_item_with_mode("quickfix", "MARK")
end
---@private
function M.add_item_mark_loc()
  add_item_with_mode("loclist", "MARK")
end
---@private
function M.add_item_fix_qf()
  add_item_with_mode("quickfix", "FIX")
end
---@private
function M.add_item_fix_loc()
  add_item_with_mode("loclist", "FIX")
end
---@private
function M.add_item_note_qf()
  add_item_with_mode("quickfix", "NOTE")
end
---@private
function M.add_item_note_loc()
  add_item_with_mode("loclist", "NOTE")
end
---@private
function M.add_item_debug_qf()
  add_item_with_mode("quickfix", "DEBUG")
end
---@private
function M.add_item_debug_loc()
  add_item_with_mode("loclist", "DEBUG")
end

local function delete_mark_builtin()
  local marks = {}
  for i = string.byte "a", string.byte "z" do
    local mark = string.char(i)
    local mark_line = vim.fn.line("'" .. mark)
    if mark_line == vim.fn.line "." then
      table.insert(marks, mark)
    end
  end

  if #marks > 0 then
    vim.cmd("delmarks " .. table.concat(marks, ""))
  end
end

local function delete_mark(pos, pos_2)
  QfbookmarkUtils.not_implemented_yet "delete mark"
end

---@private
function M.delete_mark()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  delete_mark(bufnr, pos[1])
  delete_mark_builtin()
end
---@private
function M.delete_all_marks()
  QfbookmarkUtils.not_implemented_yet()
end

---@param list_type QFBookListType
---@param force_close? boolean
---@private
local function toggle_list(list_type, force_close)
  force_close = force_close or false

  local is_location_target = list_type == "loclist"
  local cmd_ = is_location_target and { "lclose", Config.window.layout.lopen }
    or { "cclose", Config.window.layout.copen }
  local is_open, qf_or_loclist = is_vim_list_open()

  if (is_open and (list_type == qf_or_loclist)) or force_close then
    vim.fn.win_gotoid(last_winid)
    vim.cmd(cmd_[1])
    return
  end

  if vim.bo.filetype == "qf" then
    vim.cmd.wincmd "p"
  end

  local list = QfbookmarkUtils.get_list_qf(is_location_target)
  if not vim.tbl_isempty(list) then
    last_winid = vim.fn.win_getid()
    vim.cmd(cmd_[2])
    return
  end

  local msg_prefix = (is_location_target and "LocList" or "QuickFix")
  QfbookmarkUtils.warn(msg_prefix .. " items is empty")

  if vim.bo[0].filetype == "qf" then
    vim.cmd.wincmd "p"
  end
end

---@private
function M.toggle_open_qflist()
  toggle_list "quickfix"
end
---@private
function M.toggle_open_loclist()
  toggle_list "loclist"
end

---@private
function M.open_item_qf()
  local list_type = QfbookmarkUtils.is_loclist() and "loclist" or "quickfix"
  local is_center = Config.window.actions.auto_center
  local is_ispanded = Config.window.actions.auto_unfold
  QfbookmarkNav.handle_open("default", is_center, is_ispanded)

  if Config.keymaps.open_item.default.auto_close then
    toggle_list(list_type, true)
  end
end
---@private
function M.open_item_in_tab()
  local list_type = QfbookmarkUtils.is_loclist() and "loclist" or "quickfix"
  local is_center = Config.window.actions.auto_center
  local is_ispanded = Config.window.actions.auto_unfold
  QfbookmarkNav.handle_open("tabnew", is_center, is_ispanded)

  if Config.keymaps.open_item.tab.auto_close then
    toggle_list(list_type, true)
  end
end
---@private
function M.open_item_in_split()
  local list_type = QfbookmarkUtils.is_loclist() and "loclist" or "quickfix"
  local is_center = Config.window.actions.auto_center
  local is_ispanded = Config.window.actions.auto_unfold
  QfbookmarkNav.handle_open("split", is_center, is_ispanded)

  if Config.keymaps.open_item.split.auto_close then
    toggle_list(list_type, true)
  end
end
---@private
function M.open_item_in_vsplit()
  local list_type = QfbookmarkUtils.is_loclist() and "loclist" or "quickfix"
  local is_center = Config.window.actions.auto_center
  local is_ispanded = Config.window.actions.auto_unfold
  QfbookmarkNav.handle_open("vsplit", is_center, is_ispanded)

  if Config.keymaps.open_item.vsplit.auto_close then
    toggle_list(list_type, true)
  end
end

---@private
function M.next_item()
  local is_center = Config.window.actions.auto_center
  local is_ispanded = Config.window.actions.auto_unfold
  QfbookmarkNav.handle_nav(false, "open", is_center, is_ispanded, false)
end
---@private
function M.prev_item()
  local is_center = Config.window.actions.auto_center
  local is_ispanded = Config.window.actions.auto_unfold
  QfbookmarkNav.handle_nav(true, "open", is_center, is_ispanded, false)
end
---@private
function M.next_hist()
  QfbookmarkNav.handle_hist(Config.window.notify.plugin)
end
---@private
function M.prev_hist()
  QfbookmarkNav.handle_hist(Config.window.notify.plugin, true)
end

---@private
function M.move_up()
  if not Config.window.layout.enabled then
    return
  end
  QfbookmarkWindow.move_to("above", function(list_type)
    toggle_list(list_type, false)
  end)
end
---@private
function M.move_bottom()
  if not Config.window.layout.enabled then
    return
  end
  QfbookmarkWindow.move_to("bottom", function(list_type)
    toggle_list(list_type, false)
  end)
end

---@private
function M.integrations_trouble_qflist()
  if Config.keymaps.integrations.trouble.enabled then
    local trouble = require "qfbookmark.integrations.trouble"
    if vim.bo.filetype == "qf" then
      trouble.handle_toggle_qf(false, "quickfix")
    end
    if vim.bo.filetype == "trouble" then
      trouble.handle_toggle_qf(true, "quickfix")
    end
  end
end
---@private
function M.integrations_trouble_loclist()
  if Config.keymaps.integrations.trouble.enabled then
    local trouble = require "qfbookmark.integrations.trouble"
    if vim.bo.filetype == "qf" then
      if QfbookmarkUtils.is_loclist() then
        trouble.handle_toggle_qf(false, "loclist")
      end
    end
    if vim.bo.filetype == "trouble" then
      trouble.handle_toggle_qf(true, "loclist", true)
    end
  end
end
---@private
function M.integrations_cmdline_strings()
  local mapping_cmdline = Config.keymaps.integrations.cmdline_strings
  if mapping_cmdline.enabled then
    local cmdline_strs = require "qfbookmark.integrations.cmdline-strings"
    cmdline_strs.handle_mappings(mapping_cmdline)
  end
end
---@private
function M.integrations_grugfar_qflist()
  local keymap_grugfar_opts = Config.keymaps.integrations.grugfar
  if keymap_grugfar_opts.enabled then
    local grugfar = require "qfbookmark.integrations.grugfar"
    if QfbookmarkUtils.is_loclist() then
      grugfar.handle_toggle_qf("loclist", false, true)
    else
      grugfar.handle_toggle_qf("quickfix", false)
    end
  end
end

local is_open_global_note
local window_command

---@param first_close? boolean
---@private
local function __note(first_close)
  first_close = first_close or false

  local note = require "qfbookmark.note"
  local note_window_opts = Config.window.note
  note.handle_open(is_open_global_note, window_command, note_window_opts, first_close)
end
---@private
function M.toggle_open_note_global()
  if not window_command then
    window_command = QfbookmarkWindow.get_size_note_window(Config.window.note)
  end

  is_open_global_note = true
  __note()
end
---@private
function M.toggle_open_note_local()
  if not window_command then
    window_command = QfbookmarkWindow.get_size_note_window(Config.window.note)
  end
  is_open_global_note = false
  __note()
end
---@private
function M.toggle_rotate_note_window()
  local opts_note_window = Config.window.note
  local next_win_layout = QfbookmarkWindow.get_next_rotate_note_window(opts_note_window)
  window_command = next_win_layout
  __note(true)
end

return M
