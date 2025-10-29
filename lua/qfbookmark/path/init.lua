local M = {}

local Config = require("qfbookmark.config").defaults
local QfbookmarkUtils = require "qfbookmark.utils"
local QfbookmarkPathUtils = require "qfbookmark.path.utils"
local QfbookmarkUI = require "qfbookmark.ui"

M.path_opts = {
  __global = Config.save_dir .. "/__global",
  __local = Config.save_dir .. "/__local",

  current_target = "",
}

---@return string | function | table | nil
local function get_hash_note()
  local root = vim.uv.cwd()
  if root then
    return QfbookmarkPathUtils.get_hash_note(vim.loop.fs_realpath(root))
  end
  return nil
end

---@return string
---@private
function M.get_basename_cwd_project()
  local sha_path = get_hash_note()
  if sha_path then
    return QfbookmarkPathUtils.get_base_path_root(Config.save_dir) .. "-" .. sha_path
  end
  return M.path_opts.__global
end

---@param is_global boolean
---@return string
---@private
function M.get_target_path(is_global)
  local path

  path = M.path_opts.__global
  if not is_global then
    M.path_opts.__local = M.get_basename_cwd_project()
    path = M.path_opts.__local
  end

  M.path_opts.current_target = path
  return M.path_opts.current_target
end

---@param is_global boolean
---@private
function M.setup_path(is_global)
  local path = M.get_target_path(is_global)
  if not QfbookmarkPathUtils.is_dir(path) then
    QfbookmarkPathUtils.create_dir(path)
  end
end

---@param base_path string
---@param title string
---@param is_loc boolean
---@return string, string
local function format_filename_json(base_path, title, is_loc)
  local qf_title = QfbookmarkUtils.get_title_qf(is_loc)

  local fmt_str_title = function(prefix, str_title)
    prefix = #prefix > 0 and "_" .. prefix .. "-" or "-"
    prefix = prefix .. "[" .. str_title .. "]"
    return prefix
  end

  local prefix = ""

  -- TODO: ini kenapa ada title [FzfLua] bla bla bla
  -- apakah ada gw set dengan prefix title tersebut?
  -- coba diselediki

  if qf_title:match "%[FzfLua%]%sfiles:%s" then
    -- prefix = qf_title:gsub("%[FzfLua%]%sfiles:%s", "")
    prefix = fmt_str_title(prefix, "fzflua-file")
  end

  if qf_title:match "%[FzfLua%]%slive_grep_glob:%s" then
    -- prefix = qf_title:gsub("%[FzfLua%]%slive_grep_glob:%s", "")
    prefix = fmt_str_title(prefix, "fzflua-grep")
  end

  if qf_title:match "%[FzfLua%]%sblines:%s" then
    -- prefix = qf_title:gsub("%[FzfLua%]%sblines:%s", "")
    prefix = fmt_str_title(prefix, "fzflua-blines")
  end

  if qf_title:match "Fzf_diffview" then
    -- prefix = qf_title:gsub("Fzf_diffview", "")
    prefix = fmt_str_title(prefix, "fzfdiffview")
  end

  -- TODO: untuk prefix Octo, sepertinya format title dari plugin Octo tidak ada hanya tanda kurung '()'
  -- ini membuat susah untuk di buat format
  -- if qf_title:match("%s%(%)") then
  -- 	local qf_list = vim.fn.getqflist({ winid = 0, items = 0 })
  -- 	print(vim.inspect(qf_list.items))
  -- 	-- prefix = qf_title:gsub("%[FzfLua%]%sfiles:%s", "")
  -- 	-- prefix = prefix .. "_"
  -- end

  local fname = title .. prefix .. ".json"
  local fname_path = base_path .. "/" .. fname
  return fname_path, fname
end

---@param list_items QFBookLists
---@param is_loc boolean
---@private
function M.save_data_lists(list_items, is_loc)
  is_loc = is_loc or false

  QfbookmarkUI.input(function(input_msg)
    vim.cmd "startinsert!"
    -- If `value` contains spaces, concat it them with underscore
    if #input_msg == 0 or input_msg == "" then
      return
    end

    local title = input_msg

    title = title:gsub("%s", "_")
    title = title:gsub("%.", "_")

    local fname_path, fname = format_filename_json(M.path_opts.current_target, title, is_loc)

    QfbookmarkPathUtils.write_to_file(list_items, fname_path)

    QfbookmarkUtils.info(string.format("Save successful! Data has been saved to: %s", fname))

    vim.cmd "stopinsert"
  end, "Save")
end

---@param path string
---@private
function M.is_json_path_exists(path)
  if not QfbookmarkPathUtils.is_dir(path) then
    return false
  end
  return QfbookmarkPathUtils.is_file_json_found_on_path(path)
end

---@param path string
---@return QFBookLists | nil
---@private
function M.read_from_file_json(path)
  if not QfbookmarkPathUtils.is_file(path) then
    QfbookmarkUtils.error("Cant find this file:`" .. path .. "`")
    return
  end

  local raw_data_json = QfbookmarkPathUtils.get_file_read(path)

  local tbl_outputs = QfbookmarkPathUtils.fn_json_decode(raw_data_json)

  if not tbl_outputs then
    return
  end

  if vim.tbl_isempty(tbl_outputs) then
    return
  end

  return tbl_outputs
end

return M
