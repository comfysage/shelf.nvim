---@class Bufferlist
---@field __index Bufferlist
---@field config table
---@field list Bufferlist__list

---@type Bufferlist
---@diagnostic disable-next-line missing-fields
local Bufferlist = {}

Bufferlist.__index = Bufferlist

---@alias Bufferlist__list { [integer]: { [1]: integer, [2]: string } }

---@return Bufferlist__list
local function create_list()
  local old_list = _G.bufferlist and _G.bufferlist.list or {}
  local bufnr_list = vim.api.nvim_list_bufs()
  local list = {}
  local _added = {}

  for _, item in ipairs(old_list) do
    local bufnr = item[1]
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr) then
      list[#list + 1] = { bufnr, nil }
      _added[bufnr] = true
    end
  end

  for _, bufnr in ipairs(bufnr_list) do
    if not _added[bufnr] then
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr) then
        list[#list + 1] = { bufnr, nil }
      end
    end
  end

  list = vim.tbl_filter(function(item)
    if 1 ~= vim.fn.buflisted(item[1]) then
      return false
    end
    -- if string.len(item[2]) == 0 then
    --   return false
    -- end
    return true
  end, list)
  list = vim.tbl_map(function(item)
    return { item[1], vim.api.nvim_buf_get_name(item[1]) }
  end, list)

  return list
end

---@class Bufferlist
---@field new fun(self: Bufferlist): Bufferlist
function Bufferlist:new()
  local bufferlist = setmetatable({
    config = shelf_config,
    list = create_list(),
  }, self)

  return bufferlist
end

---@class Bufferlist
---@field get_index fun(self: Bufferlist, props: { buf?: integer, name?: string }): integer
function Bufferlist:get_index(props)
  if not (props.name or props.buf) then return 0 end

  for i, v in ipairs(self.list) do
    if (props.buf and v[1] == props.buf) or (props.name and v[2] == props.name) then
      return i
    end
  end

  return 0
end

---@class Bufferlist
---@field delete fun(self: Bufferlist, index: integer)
function Bufferlist:delete(index)
  if not index then return end

  local item = self.list[index]
  if not item then return end

  print(string.format('bufferlist: delete buffer %d [%s]', item[1], item[2]))
  vim.api.nvim_buf_delete(item[1], {})
end

---@class Bufferlist
---@field add fun(self: Bufferlist, index: integer, name: string)
function Bufferlist:add(index, name)
  if not index and not name then return end

  local nr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(nr, name)
  vim.api.nvim_buf_call(nr, function()
    vim.cmd.buffer()
  end)

  table.insert(self.list, index, { nr, name })
end

---@class Bufferlist
---@field append fun(self: Bufferlist, name: string)
function Bufferlist:append(name)
  if not name then return end

  self:add(#self.list + 1, name)
end

---@class Bufferlist
---@field move fun(self: Bufferlist, old: integer, new: integer)
function Bufferlist:move(old, new)
  vim.notify(string.format('move [%d] to [%d]', old, new), vim.log.levels.DEBUG)
  local value = self.list[old]
  table.remove(self.list, old)
  table.insert(self.list, new, value)
end

---@class Bufferlist
---@field open fun(self: Bufferlist, index: integer)
function Bufferlist:open(index)
  local item = self.list[index]
  if not item then return end
  local nr = item[1]
  vim.api.nvim_set_current_buf(nr)
end

_G.bufferlist = Bufferlist:new()

return _G.bufferlist
