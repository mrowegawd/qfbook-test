local Plenary_path = require "plenary.path"

local M = {}

---@param filename string
---@return boolean | string
function M.exists(filename)
  local stat
  if filename then
    stat = vim.loop.fs_stat(filename)
  end

  return stat and stat.type or false
end

---@param filename string
---@return boolean
function M.is_dir(filename)
  return M.exists(filename) == "directory"
end

---@return boolean
function M.is_file(filename)
  return M.exists(filename) == "file"
end

function M.create_file(path)
  local p = Plenary_path.new(path)
  if not p:exists() then
    p:touch()
  end
end

function M.create_dir(path)
  local p = Plenary_path.new(path)
  if not p:exists() then
    p:mkdir()
  end
end

---@return string
local function __get_cwd_root()
  local HAVE_GITSIGNS = pcall(require, "gitsigns")

  ---@diagnostic disable-next-line: undefined-field
  local status = vim.b.gitsigns_status_dict or nil

  local root_path = ""
  if not HAVE_GITSIGNS or status == nil or status["root"] == nil then
    root_path = vim.fn.getcwd()
  else
    root_path = status["root"]
  end

  if #root_path > 0 then
    root_path = vim.fs.basename(root_path)
  end

  return root_path
end

---@param path string
---@param is_global boolean
---@return string
function M.get_base_path_root(path, is_global)
  is_global = is_global or false

  local full_path = path

  if not is_global then
    local root_path = __get_cwd_root()
    full_path = full_path .. "/" .. root_path
  end
  return full_path
end

---@return string | function| table
function M.get_hash_note(filePath)
  local SHA = require "qfbookmark.path.sha"
  return SHA.sha1(filePath)
end

---@return string
function M.json_encode(tbl)
  return vim.json.encode(tbl)
end

---@return any
function M.json_decode(tbl)
  return vim.json.decode(tbl)
end

---@param tbl string[]
---@return any
function M.fn_json_decode(tbl)
  return vim.fn.json_decode(tbl)
end

---@param list_items QFBookLists
---@param path_fname string
function M.write_to_file(list_items, path_fname)
  if list_items.items and list_items.items == 0 then
    error [[`tbl` must contains { items = {}, title = "" }]]
  end

  local tbl_json = M.json_encode(list_items)
  vim.fn.writefile({ tbl_json }, path_fname)
end

---@return string[]
function M.get_file_read(fname_path)
  return vim.fn.readfile(fname_path)
end

---@return boolean
function M.is_file_json_found_on_path(path)
  local scripts = vim.api.nvim_exec2(string.format([[!find %s -type f -name "*.json"]], path), { output = true })
  if scripts.output ~= nil then
    local res = vim.split(scripts.output, "\n")
    local found = false
    for index = 2, #res do
      local item = res[index]
      if #item > 0 then
        found = true
      end
    end

    return found
  end

  return false
end

return M
