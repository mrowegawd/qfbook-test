local M = {}

---@type QFBookListResults
local results = {
  quickfix = {
    title = "",
    items = {},
  },
  location = {
    title = "",
    items = {},
  },
}

---@param list_items QFBookLists
---@param is_loc? boolean
---@param winid? integer
---@param mode? string
function M.save_to_qf(list_items, is_loc, mode, winid)
  is_loc = is_loc or false
  mode = mode or " "

  if not is_loc then
    vim.fn.setqflist({}, mode, { items = list_items.items, title = list_items.title })
    return
  end

  winid = winid or vim.api.nvim_get_current_win()
  vim.fn.setloclist(winid, {}, mode, { items = list_items.items, title = list_items.title })
end

---@param is_loc? boolean
function M.get_title_qf(is_loc)
  is_loc = is_loc or false

  if not is_loc then
    return vim.fn.getqflist({ title = 0 }).title
  end
  return vim.fn.getloclist(0, { title = 0 }).title
end

---@param is_loc? boolean
---@return string
function M.get_current_qf_idx(is_loc)
  is_loc = is_loc or M.is_loclist()

  if not is_loc then
    return vim.fn.getqflist({ idx = 0 }).idx
  end

  return vim.fn.getloclist(0, { idx = 0 }).idx
end

---@param winnr integer
---@return boolean
function M.is_quickfix_win(winnr)
  return vim.fn.getwinvar(winnr, "&buftype") == "quickfix"
end

---@param winnr integer
---@return boolean
function M.is_loclist_win(winnr)
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid(winnr))[1]
  return M.is_quickfix_win(winnr) and wininfo.loclist == 1
end

---@param is_loc? boolean
function M.get_list_qf(is_loc)
  is_loc = is_loc or false

  if not is_loc then
    return vim.fn.getqflist()
  end
  local winid = vim.api.nvim_get_current_win()
  return vim.fn.getloclist(winid)
end

---@param is_loc? boolean
---@return QFBookListResults
function M.get_data_qf(is_loc)
  is_loc = is_loc or false

  if not is_loc then
    local qf_list = M.get_list_qf()
    local qf_title = M.get_title_qf()
    if #qf_list > 0 then
      results.quickfix.title = qf_title
      results.quickfix.items = vim.tbl_map(function(item)
        return {
          filename = item.bufnr and vim.api.nvim_buf_get_name(item.bufnr),
          module = item.module,
          lnum = item.lnum,
          end_lnum = item.end_lnum,
          col = item.col,
          end_col = item.end_col,
          vcol = item.vcol,
          nr = item.nr,
          pattern = item.pattern,
          text = item.text,
          type = item.type,
          valid = item.valid,
        }
      end, qf_list)
    end

    return results
  end

  local loc_title = M.get_title_qf(true)
  local loc_list = M.get_list_qf(true)
  if #loc_list > 0 then
    results.location.title = loc_title
    results.location.items = vim.tbl_map(function(item)
      return {
        filename = item.bufnr and vim.api.nvim_buf_get_name(item.bufnr),
        module = item.module,
        lnum = item.lnum,
        end_lnum = item.end_lnum,
        col = item.col,
        end_col = item.end_col,
        vcol = item.vcol,
        nr = item.nr,
        pattern = item.pattern,
        text = item.text,
        type = item.type,
        valid = item.valid,
      }
    end, loc_list)
  end

  return results
end

---@param is_loc? boolean
---@return QFBookLists | nil
function M.get_populate_data_qf(is_loc)
  is_loc = is_loc or false
  local qf_list = {}
  local data_lists = M.get_data_qf(is_loc)
  if is_loc then
    qf_list = data_lists.location
  else
    qf_list = data_lists.quickfix
  end

  if vim.tbl_isempty(qf_list.items) then
    return
  end

  return qf_list
end

---@param buf? integer
function M.is_loclist(buf)
  buf = buf or 0
  return vim.fn.getloclist(buf, { filewinid = 1 }).filewinid ~= 0
end

---@param title? string
local function get_prefix_notify_title(title)
  if not title or (title == "") then
    title = "Qfbookmark"
  end
  return title
end

---@param msg string
---@param title? string
function M.info(msg, title)
  title = get_prefix_notify_title(title)
  vim.notify(msg, vim.log.levels.INFO, { title = title })
end

---@param msg string
---@param title? string
function M.warn(msg, title)
  title = get_prefix_notify_title(title)
  vim.notify(msg, vim.log.levels.WARN, { title = title })
end

---@param msg string
---@param title? string
function M.error(msg, title)
  title = get_prefix_notify_title(title)
  vim.notify(msg, vim.log.levels.WARN, { title = title })
end

---@param msg? string
function M.not_implemented_yet(msg)
  if msg == nil then
    msg = ""
  end
  if #msg > 0 then
    msg = "Not impelemented, for -> " .. msg
  else
    msg = "Not impelemented yet"
  end
  M.warn(msg)
end

---@param str string
---@return string
local rstrip_whitespace = function(str)
  str = string.gsub(str, "%s+$", "")
  return str
end

---@param str string
---@param limit? string|nil
---@return string
local lstrip_whitespace = function(str, limit)
  if limit ~= nil then
    local num_found = 0
    while num_found < limit do
      str = string.gsub(str, "^%s", "")
      num_found = num_found + 1
    end
  else
    str = string.gsub(str, "^%s+", "")
  end
  return str
end

---@param str string
---@return string
function M.strip_whitespace(str)
  if str then
    return rstrip_whitespace(lstrip_whitespace(str))
  end
  return ""
end

---@param list_items QFBookLists
---@param cmd_open string
---@param is_loc? boolean
---@param winid? string
function M.save_to_qf_and_auto_open_qf(list_items, cmd_open, is_loc, winid)
  M.save_to_qf(list_items, is_loc, winid)
  vim.cmd(cmd_open)
end

---@param wins string|string[]
function M.windows_is_opened(wins)
  local ft_wins = { "incline" }

  if type(wins) == "table" then
    if #wins > 0 then
      for _, x in pairs(wins) do
        ft_wins[#ft_wins + 1] = x
      end
    end
  end

  if type(wins) == "string" then
    ft_wins[#ft_wins + 1] = wins
  end

  local outline_tbl = { found = false, winbufnr = 0, winnr = 0, winid = 0, ft = "" }
  for _, winnr in ipairs(vim.api.nvim_list_wins()) do
    local win_bufnr = vim.api.nvim_win_get_buf(winnr)

    if tonumber(win_bufnr) == 0 then
      return outline_tbl
    end

    local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = win_bufnr })
    local buf_buftype = vim.api.nvim_get_option_value("buftype", { buf = win_bufnr })

    local winid = vim.fn.win_findbuf(win_bufnr)[1] -- example winid: 1004, 1005

    if vim.tbl_contains(ft_wins, buf_ft) or vim.tbl_contains(ft_wins, buf_buftype) then
      outline_tbl = { found = true, winbufnr = win_bufnr, winnr = winnr, winid = winid, ft = buf_ft }
    end
  end

  return outline_tbl
end

---@param filename string
---@return integer | nil
local function is_file_in_buffers(filename)
  local buffers = vim.api.nvim_list_bufs()

  for _, buf in ipairs(buffers) do
    local bufname = vim.api.nvim_buf_get_name(buf)
    if bufname == filename then
      return buf
    end
  end

  return nil
end

---@param filename string
function M.delete_buffer_by_name(filename)
  local buf = is_file_in_buffers(filename)
  if buf then
    vim.api.nvim_buf_delete(buf, { force = true })
    return true
  end
  return false
end

---@param key string
---@param mode? KeyMode
function M.feedkey(key, mode)
  mode = mode or "n"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

return M
