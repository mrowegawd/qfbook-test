local M = {}

---@type QFBookmarkConfig
M.defaults = {
  save_dir = vim.fn.stdpath "data" .. "/qfbookmark",
  picker = "fzf-lua",
  extmarks = {
    enabled = true,
    priority = 100,
    excluded = {
      buftypes = {},
      filetypes = {},
    },
    builtin_marks = false,
    cyclic_navigation = true,
    refresh_interval = 250,
    keywords = {
      MARK = { icon = "📌", hl_group = "QFBookMark", alt = " -> " },
      FIX = { icon = "🔧", hl_group = "QFBookFix", alt = " -> " },
      DEBUG = { icon = "🚧", hl_group = "QFBookDebug", alt = " -> " },
      NOTE = { icon = "📝", hl_group = "QFBookNote", alt = " -> " },
      --   done = "✅",
      --   undone = "❌",
    },
  },
  persistence = {
    builtin_marks = false,
    force_write_shada = false,
  },
  window = {
    notify = { mark = false, plugin = true },
    theme = { enabled = true, maxheight = 10 },
    layout = {
      enabled = true,
      copen = "belowright copen",
      lopen = "belowright lopen",
    },
    actions = {
      auto_center = true,
      auto_unfold = true,
    },
    note = {
      open_cmd = "topleft",
      size_split = 12,
      size_vsplit = 60,
      filetype = "org", -- Ex: "orgmode" "norg", "markdown", "text"
      file_ext = "org", -- Ex: "org" "norg" "md" "txt"
      -- border = "rounded",
      -- winblend = 10,
    },
    popup = {
      winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
      higroup_title = "Function",
      mark = false,
      icons = {
        box_message = " ", -- " ",
      },
    },
  },
  keymaps = {
    disable_all = false,

    actions = { -- General actions
      delete_mark = "dm",
      delete_mark_buffer = "dM",
      delete_item = "<Leader>qd",
      delete_item_all = "<Leader>qD",
      rename_title = "<Leader>qr",
      save_or_load = "<Leader>qy",
    },

    open_item = {
      default = { keys = { "o", "<CR>" }, auto_close = true },
      split = { keys = { "ss", "<C-s>" }, auto_close = false },
      vsplit = { keys = { "sv", "<C-v>" }, auto_close = false },
      tab = { keys = { "st", "tn" }, auto_close = true },
    },

    navigation = {
      next = "<c-n>",
      prev = "<c-p>",
      next_hist = "gl",
      prev_hist = "gh",
      window = {
        move_up = "<a-k>",
        move_down = "<a-j>",
        rotate_layout_note = "<a-=>",
      },
    },

    quickfix = {
      toggle_open = "<Leader>qj",
      mark = "<Leader>qq",
      fix = "<Leader>qf",
      debug = "<Leader>qd",
      note = "<Leader>qn",
    },
    loclist = {
      toggle_open = "<Leader>ql",
      mark = "<Leader>qQ",
      fix = "<Leader>qF",
      debug = "<Leader>qD",
      note = "<Leader>qN",
    },
    note = {
      toggle_local_note = "<Leader>fn",
      toggle_global_note = "<Leader>fp",
    },
    integrations = {
      trouble = { enabled = true, toggle_qflist = "Q", toggle_loclist = "L" },
      grugfar = { enabled = true, toggle = "<Localleader>gg" },
      cmdline_strings = {
        enabled = true,
        commands = {
          {
            key = "<Leader>qrl",
            cmd = "cdo %s/status//gi | update",
            desc = "Descriptions about cdo..",
            mode = "n", -- "i", "x", "s", "n", "o"
          },
        },
      },
    },
  },
}

local function merge_settings(defaults, user_opts)
  vim.validate {
    defaults = { defaults, "table" },
    user_opts = { user_opts, "table" },
  }
  return vim.tbl_deep_extend("force", defaults, user_opts)
end

---@return QFBookmarkConfig
function M.update_settings(user_opts)
  user_opts = user_opts or {}
  M.defaults = merge_settings(M.defaults, user_opts)

  -- Makes the quickfix and local list prettier. Borrowed from nvim-bqf.
  -- function _G.qftf(info)
  --   local items
  --   local ret = {}
  --   if info.quickfix == 1 then
  --     items = fn.getqflist({ id = info.id, items = 0 }).items
  --   else
  --     items = fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  --   end
  --   local limit = 60
  --   local fname_fmt1, fname_fmt2 = "%-" .. limit .. "s", "…%." .. (limit - 1) .. "s"
  --   local valid_fmt = "%s │%5d:%-3d│%s %s"
  --   for i = info.start_idx, info.end_idx do
  --     local e = items[i]
  --     local fname = ""
  --     local str
  --     if e.valid == 1 then
  --       if e.bufnr > 0 then
  --         fname = fn.bufname(e.bufnr)
  --         if fname == "" then
  --           fname = "[No Name]"
  --         else
  --           fname = fname:gsub("^" .. vim.env.HOME, "~")
  --         end
  --         if #fname <= limit then
  --           fname = fname_fmt1:format(fname)
  --         else
  --           fname = fname_fmt2:format(fname:sub(1 - limit))
  --         end
  --       end
  --       local lnum = e.lnum > 99999 and -1 or e.lnum
  --       local col = e.col > 999 and -1 or e.col
  --       local qtype = e.type == "" and "" or " " .. e.type:sub(1, 1):upper()
  --       str = valid_fmt:format(fname, lnum, col, qtype, e.text)
  --     else
  --       str = e.text
  --     end
  --     table.insert(ret, str)
  --   end
  --   return ret
  -- end

  -- local function addjustWindowHWQf(maxheight)
  --   maxheight = maxheight or 7
  --   local l = 1
  --   local n_lines = 0
  --   local w_width = fn.winwidth(vim.api.nvim_get_current_win())
  --
  --   for i = l, fn.line "$" do
  --     local l_len = fn.strlen(fn.getline(l)) + 0.0
  --     local line_width = l_len / w_width
  --     n_lines = n_lines + fn.float2nr(fn.ceil(line_width))
  --     i = i + 1
  --   end
  --   --
  --   local height = math.min(n_lines, maxheight)
  --   vim.cmd(fmt("%swincmd _", height + 1))
  -- end

  -- if settings.theme_list.set.enabled then
  --   vim.o.qftf = "{info -> v:lua.qftf(info)}" -- uncomment this line if needed..
  -- end

  -- if settings.theme_list.auto_height.enabled then
  --   local augroup = vim.api.nvim_create_augroup("QFSiletThemeQF", { clear = true })
  --   vim.api.nvim_create_autocmd("FileType", {
  --     pattern = { "qf" },
  --     group = augroup,
  --     callback = function()
  --       addjustWindowHWQf(settings.theme_list.maxheight)
  --     end,
  --   })
  -- end

  -- if settings.marks.enabled then
  --   require("qfsilet.marks").setup(settings.marks.refresh_interval)
  -- end
  --
  -- for i_ext, _ in pairs(Visual.extmarks) do
  --   for i_ext_set, _ in pairs(settings.extmarks) do
  --     if i_ext == i_ext_set then
  --       Visual.extmarks[i_ext] = settings.extmarks[i_ext_set]
  --     end
  --   end
  -- end

  -- setup_highlight_groups()

  return M.defaults
end

---@param opts QFBookmarkConfig
function M.init(opts)
  local PathUtil = require "qfbookmark.path.utils"
  if not PathUtil.is_dir(opts.save_dir) then
    PathUtil.create_dir(opts.save_dir)
  end

  require("qfbookmark.mappings").setup()
end

return M
