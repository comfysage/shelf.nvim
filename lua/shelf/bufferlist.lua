---@class shelf.types.bufferlist
---@field __index shelf.types.bufferlist
---@field list shelf.types.bufferlist.list

---@type shelf.types.bufferlist
---@diagnostic disable-next-line missing-fields
local Bufferlist = {}

Bufferlist.__index = Bufferlist

---@alias shelf.types.bufferlist.list { [integer]: { [1]: integer, [2]: string } }

---@param name string
---@return integer
local function create_buf(name)
  vim.notify(('creating buffer [%s]'):format(name), vim.log.levels.DEBUG)
  local nr = vim.fn.bufadd(name)
  vim.api.nvim_buf_call(nr, function()
    vim.cmd.buffer()
  end)

  return nr
end

---@return shelf.types.bufferlist.list
local function create_list()
  local old_list = _G.bufferlist and _G.bufferlist.list or {}
  local bufnr_list = vim.api.nvim_list_bufs()
  local list = {}
  local _added = {}

  for _, item in ipairs(old_list) do
    local bufnr = item[1]
    local name = item[2]
    if not vim.api.nvim_buf_is_valid(bufnr) then
      bufnr = -1
    end
    list[#list + 1] = { bufnr, name }
    _added[name] = true
  end

  for _, bufnr in ipairs(bufnr_list) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if not _added[name] then
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr) then
        list[#list + 1] = { bufnr, name }
      end
    end
  end

  list = vim.tbl_filter(function(item)
    if item[1] > -1 then
      if 1 ~= vim.fn.buflisted(item[1]) then
        return false
      end
    end
    -- if string.len(item[2]) == 0 then
    --   return false
    -- end
    return true
  end, list)

  return list
end

---@class shelf.types.bufferlist
---@field new fun(self: shelf.types.bufferlist): shelf.types.bufferlist
function Bufferlist:new()
  local bufferlist = setmetatable({
    list = create_list(),
  }, self)

  return bufferlist
end

---@class shelf.types.bufferlist
---@field update fun(self: shelf.types.bufferlist): shelf.types.bufferlist
function Bufferlist:update()
  self.list = create_list()
end

---@class shelf.types.bufferlist
---@field get_index fun(self: shelf.types.bufferlist, props: { buf?: integer, name?: string }): integer
function Bufferlist:get_index(props)
  if not (props.name or props.buf) then return 0 end

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
  if not index then return end

  local item = self.list[index]
  if not item then return end

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
---@field add fun(self: shelf.types.bufferlist, index: integer, name: string)
function Bufferlist:add(index, name)
  if not index and not name then return end

  table.insert(self.list, index, { -1, name })
end

---@class shelf.types.bufferlist
---@field append fun(self: shelf.types.bufferlist, name: string)
function Bufferlist:append(name)
  if not name then return end

  self:add(#self.list + 1, name)
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
  if not item then return end
  local nr = item[1]
  if nr < 0 then
    nr = create_buf(item[2])
    self.list[index][1] = nr
  end
  vim.api.nvim_set_current_buf(nr)
end

_G.bufferlist = Bufferlist:new()

return _G.bufferlist
