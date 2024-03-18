local utils = require 'shelf.utils'

---@class shelf.types.bufferlist
---@field __index shelf.types.bufferlist
---@field list shelf.types.bufferlist.list

---@type shelf.types.bufferlist
---@diagnostic disable-next-line missing-fields
local Bufferlist = {}

Bufferlist.__index = Bufferlist

---@alias shelf.types.bufferlist.list table<integer, { [1]: integer, [2]: string }>

---@class shelf.types.bufferlist
---@field new fun(self: shelf.types.bufferlist): shelf.types.bufferlist
function Bufferlist:new()
  local bufferlist = setmetatable({
    list = {},
  }, self)

  return bufferlist
end

---@class shelf.types.bufferlist
---@field register fun(self: shelf.types.bufferlist, list: string[])
function Bufferlist:register(list)
  ---@type table<string, boolean>
  local exists = {}

  for _, item in ipairs(self.list) do
    exists[item[2]] = true
  end

  for _, name in ipairs(list) do
    if not exists[name] then
      self:append(name, vim.fn.bufnr(name))
    end
  end
end

---@class shelf.types.bufferlist
---@field register_buffers fun(self: shelf.types.bufferlist)
function Bufferlist:register_buffers()
  local buflist = vim.api.nvim_list_bufs()

  buflist = vim.tbl_filter(function(bufnr)
    if vim.bo[bufnr].buftype ~= '' then
      return false
    end
    return vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr)
  end, buflist)
  buflist = vim.tbl_map(function(bufnr)
    return vim.api.nvim_buf_get_name(bufnr)
  end, buflist)

  self:register(buflist)
end

---@class shelf.types.bufferlist
---@field fix fun(self: shelf.types.bufferlist)
function Bufferlist:fix()
  self.list = vim.tbl_filter(function(item)
    -- check for connected items
    if item[1] > -1 then
      -- check for broken connection
      if 1 ~= vim.fn.buflisted(item[1]) then
        return false
      end
    end
    return true
  end, self.list)
  self.list = vim.tbl_map(function(item)
    return { vim.fn.bufnr(item[2]), item[2] }
  end, self.list)
end

---@class shelf.types.bufferlist
---@field update fun(self: shelf.types.bufferlist)
function Bufferlist:update()
  self:register_buffers()
  self:fix()
end

---@class shelf.types.bufferlist
---@field get_index fun(self: shelf.types.bufferlist, props: { buf?: integer, name?: string }): integer
function Bufferlist:get_index(props)
  if not (props.name or props.buf) then
    return 0
  end

  for i, v in ipairs(self.list) do
    if props.name and v[2] == props.name then
      return i
    elseif props.buf and props.buf ~= -1 and v[1] == props.buf then
      return i
    end
  end

  return 0
end

---@class shelf.types.bufferlist
---@field delete fun(self: shelf.types.bufferlist, index: integer)
function Bufferlist:delete(index)
  if not index then
    return
  end

  local item = self.list[index]
  if not item then
    return
  end

  local buf, name = unpack(item, 1, 2)
  vim.notify(
    string.format('bufferlist: delete buffer %d [%s]', buf, name),
    vim.log.levels.DEBUG
  )
  if buf ~= -1 then
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.api.nvim_buf_delete(buf, {})
  end

  table.remove(self.list, index)
end

---@class shelf.types.bufferlist
---@field add fun(self: shelf.types.bufferlist, index: integer, name: string, buf?: integer)
function Bufferlist:add(index, name, buf)
  if not index and not name then
    return
  end

  table.insert(self.list, index, { buf or -1, name })
end

---@class shelf.types.bufferlist
---@field append fun(self: shelf.types.bufferlist, name: string, buf?: integer)
function Bufferlist:append(name, buf)
  if not name then
    return
  end

  self:add(#self.list + 1, name, buf)
end

---@class shelf.types.bufferlist
---@field move fun(self: shelf.types.bufferlist, old: integer, new: integer)
function Bufferlist:move(old, new)
  vim.notify(string.format('move [%d] to [%d]', old, new), vim.log.levels.DEBUG)
  local value = self.list[old]
  table.remove(self.list, old)
  table.insert(self.list, new, value)
end

---@class shelf.types.bufferlist
---@field open fun(self: shelf.types.bufferlist, index: integer)
function Bufferlist:open(index)
  local item = self.list[index]
  if not item then
    return
  end
  local nr = item[1]
  if nr < 0 then
    nr = utils.create_buf(item[2])
    self.list[index][1] = nr
  end
  vim.api.nvim_set_current_buf(nr)
end

_G.bufferlist = _G.bufferlist or Bufferlist:new()

return _G.bufferlist
