local M = {}

local api = require "obsidian.api"
local util = require "obsidian.util"

---@param opts { prompt_title: string, query_mappings: obsidian.PickerMappingTable|?, selection_mappings: obsidian.PickerMappingTable|? }|?
---@return string
M.build_prompt = function(opts)
  opts = opts or {}

  ---@type string
  local prompt = opts.prompt_title or "Find"
  if string.len(prompt) > 50 then
    prompt = string.sub(prompt, 1, 50) .. "…"
  end

  prompt = prompt .. " | <CR> confirm"

  if opts.query_mappings then
    local keys = vim.tbl_keys(opts.query_mappings)
    table.sort(keys)
    for _, key in ipairs(keys) do
      local mapping = opts.query_mappings[key]
      prompt = prompt .. " | " .. key .. " " .. mapping.desc
    end
  end

  if opts.selection_mappings then
    local keys = vim.tbl_keys(opts.selection_mappings)
    table.sort(keys)
    for _, key in ipairs(keys) do
      local mapping = opts.selection_mappings[key]
      prompt = prompt .. " | " .. key .. " " .. mapping.desc
    end
  end

  return prompt
end

---@param entry obsidian.PickerEntry
---
---@return string, { [1]: { [1]: integer, [2]: integer }, [2]: string }[]
M.make_display = function(entry)
  local buf = {}
  ---@type { [1]: { [1]: integer, [2]: integer }, [2]: string }[]
  local highlights = {}

  local icon, icon_hl

  if entry.filename then
    icon, icon_hl = api.get_icon(entry.filename)
  end

  if icon then
    buf[#buf + 1] = icon
    buf[#buf + 1] = " "
    if icon_hl then
      highlights[#highlights + 1] = { { 0, util.strdisplaywidth(icon) }, icon_hl }
    end
  end

  local display_name = ""

  if entry.text then
    display_name = entry.text
  elseif entry.user_data then
    local note_obj = entry.user_data
    if type(note_obj) == "table" and note_obj.aliases and #note_obj.aliases > 0 then
      display_name = note_obj.aliases[1]
    elseif type(note_obj) == "table" and note_obj.display_name and type(note_obj.display_name) == "function" then
      display_name = note_obj:display_name()
    elseif type(note_obj) == "table" and note_obj.title then
      display_name = note_obj.title
    elseif type(note_obj) == "table" and note_obj.id then
      display_name = note_obj.id
    elseif entry.display then
      display_name = entry.display
    else
      display_name = tostring(note_obj)
    end
  elseif entry.display then
    display_name = entry.display
  end

  if display_name ~= "" then
    buf[#buf + 1] = " "
    buf[#buf + 1] = display_name
  end

  -- Add tags if available
  local tags = nil
  if entry.user_data and type(entry.user_data) == "table" and entry.user_data.tags and #entry.user_data.tags > 0 then
    tags = entry.user_data.tags
  elseif entry.tags and #entry.tags > 0 then
    tags = entry.tags
  end

  if tags then
    local tags_str = table.concat(tags, ", ")
    buf[#buf + 1] = " ["
    buf[#buf + 1] = tags_str
    buf[#buf + 1] = "]"
  end

  return table.concat(buf, ""), highlights
end

return M
