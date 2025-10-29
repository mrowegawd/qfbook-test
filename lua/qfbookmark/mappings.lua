local qf = require "qfbookmark.qf"
local Config = require("qfbookmark.config").defaults

local M = {}

---@param keymaps_opts QFBookKeys[]
---@param is_bufnr boolean
---@param is_marks boolean
---@param is_todo_note boolean
local function set_keymaps(keymaps_opts, is_bufnr, is_marks, is_todo_note)
  is_bufnr = is_bufnr or false
  is_marks = is_marks or false
  is_todo_note = is_todo_note or false

  for _, cmd in pairs(keymaps_opts) do
    local key_func = qf[cmd.func]
    local keymap_opts = { desc = cmd.desc }
    local keys = cmd.keys
    if is_bufnr then
      keymap_opts.buffer = vim.api.nvim_get_current_buf()
    end
    if type(keys) == "table" then
      for _, k in pairs(keys) do
        vim.keymap.set(cmd.mode, k, key_func, keymap_opts)
      end
    end
    if type(keys) == "string" then
      vim.keymap.set(cmd.mode, keys, key_func, keymap_opts)
    end
  end
end

local function set_keymaps_ft(name_au, pattern, keymaps_opts)
  local augroup = vim.api.nvim_create_augroup(name_au, { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = pattern,
    group = augroup,
    callback = function()
      set_keymaps(keymaps_opts, true, false, false)
    end,
  })
end

---@param keymap_group {keymaps: QFBookKeys[], is_set?: boolean}
---@param dest QFBookKeys[]
local function append_active_keymaps(keymap_group, dest)
  local is_set = keymap_group.is_set or false
  if is_set then
    for _, keys in pairs(keymap_group.keymaps) do
      dest[#dest + 1] = keys
    end
  end
  return dest
end

---@private
function M.setup()
  ---@type QFBookKeys[]
  local keys = {
    -- TOGGLE
    {
      desc = "Qf: toggle open loclist [QFbookmark]",
      func = "toggle_open_loclist",
      keys = Config.keymaps.loclist.toggle_open,
      mode = { "n", "x" },
    },
    {
      desc = "Qf: toggle open quickfix [QFbookmark]",
      func = "toggle_open_qflist",
      keys = Config.keymaps.quickfix.toggle_open,
      mode = { "n", "x" },
    },
    -- OPEN SAVE AND LOAD
    {
      desc = "Qf: load or save qf to file [QFbookmark]",
      func = "save_or_load",
      keys = Config.keymaps.actions.save_or_load,
      mode = "n",
    },
    -- MARK
    {
      desc = "Qf: add item MARK to quickfix [QFbookmark]",
      func = "add_item_mark_qf",
      keys = Config.keymaps.quickfix.mark,
      mode = "n",
    },
    {
      desc = "Qf: add item MARK to loclist [QFbookmark]",
      func = "add_item_mark_loc",
      keys = Config.keymaps.loclist.mark,
      mode = "n",
    },
    -- FIX
    {
      desc = "Qf: add item FIX to quickfix [QFbookmark]",
      func = "add_item_fix_qf",
      keys = Config.keymaps.quickfix.fix,
      mode = "n",
    },
    {
      desc = "Qf: add item FIX to loclist [QFbookmark]",
      func = "add_item_fix_loc",
      keys = Config.keymaps.loclist.fix,
      mode = "n",
    },
    -- DEBUG
    {
      desc = "Qf: add item DEBUG to quickfix [QFbookmark]",
      func = "add_item_debug_qf",
      keys = Config.keymaps.quickfix.debug,
      mode = "n",
    },
    {
      desc = "Qf: add item DEBUG to loclist [QFbookmark]",
      func = "add_item_debug_loc",
      keys = Config.keymaps.loclist.debug,
      mode = "n",
    },
    -- NOTE
    {
      desc = "Qf: add item NOTE to quickfix [QFbookmark]",
      func = "add_item_note_qf",
      keys = Config.keymaps.quickfix.note,
      mode = "n",
    },
    {
      desc = "Qf: add item NOTE to loclist [QFbookmark]",
      func = "add_item_note_loc",
      keys = Config.keymaps.loclist.note,
      mode = "n",
    },
    -- DELETE
    {
      desc = "Qf: delete mark sign [QFbookmark]",
      func = "delete_mark",
      keys = Config.keymaps.actions.delete_mark,
      mode = "n",
    },
    {
      desc = "Qf: delete all mark buffer sign [QFbookmark]",
      func = "delete_all_marks",
      keys = Config.keymaps.actions.delete_mark_buffer,
      mode = "n",
    },

    {
      desc = "Qf: toggle open note global project [QFbookmark]",
      func = "toggle_open_note_global",
      keys = Config.keymaps.note.toggle_global_note,
      mode = "n",
    },
    {
      desc = "Qf: toggle open note local project [QFbookmark]",
      func = "toggle_open_note_local",
      keys = Config.keymaps.note.toggle_local_note,
      mode = "n",
    },
    {
      desc = "Qf: toggle rotate window note [QFbookmark]",
      func = "toggle_rotate_note_window",
      keys = Config.keymaps.navigation.window.rotate_layout_note,
      mode = "n",
    },

    -- ╭────────────────╮
    -- │ debug commands │
    -- ╰────────────────╯
    {
      desc = "Qf: -- debug -- [QFbookmark]",
      func = "integrations_cmdline_strings",
      keys = "<Leader>qP",
      mode = "n",
    },
  }

  ---@type QFBookKeys[]
  local keys_ft = {
    -- OPEN
    {
      desc = "Qf: open item [QFbookmark]",
      func = "open_item_qf",
      keys = Config.keymaps.open_item.default.keys,
      mode = "n",
    },
    {
      desc = "Qf: open item in split [QFbookmark]",
      func = "open_item_in_split",
      keys = Config.keymaps.open_item.split.keys,
      mode = { "n", "x" },
    },
    {
      desc = "Qf: open item in vsplit [QFbookmark]",
      func = "open_item_in_vsplit",
      keys = Config.keymaps.open_item.vsplit.keys,
      mode = { "n", "x" },
    },
    {
      desc = "Qf: open item in tab [QFbookmark]",
      func = "open_item_in_tab",
      keys = Config.keymaps.open_item.tab.keys,
      mode = { "n", "x" },
    },
    -- RENAME
    {
      desc = "Qf: rename title quickfix [QFbookmark]",
      func = "rename_title",
      keys = Config.keymaps.actions.rename_title,
      mode = "n",
    },
    -- NAV
    {
      desc = "Qf: next item [QFbookmark]",
      func = "next_item",
      keys = Config.keymaps.navigation.next,
      mode = { "n" },
    },
    {
      desc = "Qf: prev item [QFbookmark]",
      func = "prev_item",
      keys = Config.keymaps.navigation.prev,
      mode = { "n" },
    },
    -- DELETE
    {
      desc = "Qf: delete item [QFbookmark]",
      func = "delete_item",
      keys = Config.keymaps.actions.delete_item,
      mode = { "n" },
    },
    {
      desc = "Qf: delete all items [QFbookmark]",
      func = "delete_all_items",
      keys = Config.keymaps.actions.delete_item_all,
      mode = "n",
    },
    -- HISTORY
    {
      desc = "Qf: next history qf [QFbookmark]",
      func = "next_hist",
      keys = Config.keymaps.navigation.next_hist,
      mode = { "n", "x" },
    },
    {
      desc = "Qf: prev history qf [QFbookmark]",
      func = "prev_hist",
      keys = Config.keymaps.navigation.prev_hist,
      mode = { "n", "x" },
    },
  }

  ---@type QFBookKeys[]
  local key_ft_trouble = {
    {
      desc = "Qf: convert toggle quickfix [QFbookmark]",
      func = "integrations_trouble_qflist",
      keys = Config.keymaps.integrations.trouble.toggle_qflist,
      mode = "n",
    },
    {
      desc = "Qf: convert toggle loclist [QFbookmark]",
      func = "integrations_trouble_loclist",
      keys = Config.keymaps.integrations.trouble.toggle_loclist,
      mode = "n",
    },
  }

  append_active_keymaps({
    is_set = Config.window.layout.enabled,
    keymaps = {
      {
        desc = "Qf: move window to up [QFbookmark]",
        func = "move_up",
        keys = Config.keymaps.navigation.window.move_up,
        mode = { "n", "x" },
      },
      {
        desc = "Qf: move window to bottom [QFbookmark]",
        func = "move_bottom",
        keys = Config.keymaps.navigation.window.move_down,
        mode = { "n", "x" },
      },
    },
  }, keys_ft)
  append_active_keymaps({
    is_set = Config.keymaps.integrations.grugfar.enabled,
    keymaps = {
      {
        desc = "Qf: search in grugfar [QFbookmark integration]",
        func = "integrations_grugfar_qflist",
        keys = Config.keymaps.integrations.grugfar.toggle,
        mode = "n",
      },
    },
  }, keys_ft)
  append_active_keymaps({
    is_set = Config.keymaps.integrations.trouble.enabled,
    keymaps = {
      {
        desc = "Qf: convert trouble toggle quickfix [QFbookmark integration]",
        func = "integrations_trouble_qflist",
        keys = Config.keymaps.integrations.trouble.toggle_qflist,
        mode = "n",
      },
      {
        desc = "Qf: convert trouble toggle loclist [QFbookmark integration]",
        func = "integrations_trouble_loclist",
        keys = Config.keymaps.integrations.trouble.toggle_loclist,
        mode = "n",
      },
    },
  }, keys_ft)

  if Config.keymaps.integrations.trouble.enabled then
    set_keymaps_ft("QFBookMappingsTrouble", { "trouble" }, key_ft_trouble)
  end

  if Config.keymaps.integrations.cmdline_strings.enabled then
    require("qfbookmark.qf").integrations_cmdline_strings()
  end

  -- TODO: disable_all jika false, maka jangan diset semua, terkecuali
  -- pada bagian keymaps yang sudah di set oleh user
  -- if not Config.keymaps.disable_all then
  set_keymaps_ft("QFBookMappings", { "qf" }, keys_ft)
  set_keymaps(keys, false, false, true)
end

return M
