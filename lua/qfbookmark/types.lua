---@alias QFBookListType "loclist" | "quickfix" | "none"
---@alias QFBookState "Save Qflist" | "Save Loclist" | "Load"
---@alias QFBookCurrentState "Local" | "Global"
---@alias KeyMode "n" | "x" | "i" | "t" | "o"

---@class QFBookLists
---@field items table[]
---@field title string

---@class QFBookListResults
---@field quickfix QFBookLists
---@field location QFBookLists

---@class QFBookSpec
---@field icon string
---@field hl_group string
---@field alt string

---@class QFBookKeywords
---@field MARK QFBookSpec
---@field FIX QFBookSpec
---@field DEBUG QFBookSpec
---@field NOTE QFBookSpec

---@class QFBookExtermarks
---@field enabled boolean
---@field excluded { buftypes: string[], filetypes: string[] }
---@field builtin_marks boolean
---@field cyclic_navigation boolean
---@field priority integer
---@field refresh_interval integer
---@field keywords QFBookKeywords

---@class QFBookNotes
---@field open_cmd string
---@field size_split integer
---@field size_vsplit integer
---@field file_ext string
---@field filetype string

---@class PopupConfig
---@field winhighlight string
---@field higroup_title string
---@field mark boolean
---@field icons { box_message: string }

---@class WindowConfig
---@field notify { enabled: boolean, mark: boolean, plugin: boolean }
---@field theme { enabled: boolean, maxheight: integer }
---@field layout { enabled: boolean, copen: string, lopen: string }
---@field actions { auto_center: boolean, auto_unfold: boolean }
---@field popup PopupConfig
---@field note QFBookNotes

---@class QFBookKeymapQfSpec
---@field toggle_open string | string[]
---@field mark string | string[]
---@field fix string | string[]
---@field debug string | string[]
---@field note string | string[]

---@class QFBookItemOpenMode
---@field keys string | string[]
---@field auto_close boolean

---@class QFBookKeymapOpenItem
---@field default QFBookItemOpenMode
---@field split  QFBookItemOpenMode
---@field vsplit QFBookItemOpenMode
---@field tab QFBookItemOpenMode

---@class QFBookKeymapMoveWindow
---@field move_up string | string[]
---@field move_down string | string[]
---@field rotate_layout_note string | string[]

---@class QFBookKeymapMove
---@field next string | string[]
---@field prev string | string[]
---@field next_hist string | string[]
---@field prev_hist string | string[]
---@field window QFBookKeymapMoveWindow

---@class QFBookKeymapTrouble
---@field enabled boolean
---@field toggle_qflist string | string[]
---@field toggle_loclist string | string[]
---
---@class QFBookKeymapIntegrationSpec
---@field enabled boolean
---@field toggle string | string[]
---
---@class QFBookKeymapCMDPattern
---@field key string
---@field cmd string | function
---@field desc string
---@field mode? KeyMode

---@class QFBookKeymapCMDLineStrings
---@field enabled boolean
---@field commands QFBookKeymapCMDPattern[]

---@class QFBookKeymapNotes
---@field toggle_local_note string | string[]
---@field toggle_global_note string | string[]

---@class QFBookKeymapIntegrations
---@field trouble QFBookKeymapTrouble
---@field grugfar QFBookKeymapIntegrationSpec
---@field cmdline_strings QFBookKeymapCMDLineStrings

---@class QFBookKeymapActions
---@field delete_mark string | string[]
---@field delete_mark_buffer string | string[]
---@field delete_item string | string[]
---@field delete_item_all string | string[]
---@field rename_title string | string[]
---@field save_or_load string | string[]

---@class QFBookmarkKeymap
---@field disable_all boolean
---@field actions QFBookKeymapActions
---@field navigation QFBookKeymapMove
---@field open_item QFBookKeymapOpenItem
---@field quickfix QFBookKeymapQfSpec
---@field loclist QFBookKeymapQfSpec
---@field integrations QFBookKeymapIntegrations
---@field note QFBookKeymapNotes

---@class QFBookPersistence
---@field builtin_marks boolean
---@field force_write_shada boolean

---@class QFBookmarkConfig
---@field save_dir string
---@field picker "fzf-lua" | "default"
---@field extmarks QFBookExtermarks
---@field persistence QFBookPersistence
---@field window WindowConfig
---@field keymaps QFBookmarkKeymap

---@class QFBookKeys
---@field desc string
---@field func string
---@field keys string | string[]
---@field mode string | string[]
