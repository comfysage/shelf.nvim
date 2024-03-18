---@class shelf.types.data.value
---@field list table<string, (string[])>

---@class shelf.types.data
---@field __index shelf.types.data
---@field data shelf.types.data.value
local Data = {}

Data.__index = Data

---@class shelf.types.data
---@field new fun(self: shelf.types.data): shelf.types.data
function Data:new()
  local data = setmetatable({
    data = {
      list = {},
    },
  }, self)

  data:sync_list()

  return data
end

---@class shelf.types.data
---@field read_data fun(self: shelf.types.data): boolean, shelf.types.data.value?
function Data:read_data()
  local fh = io.open(require('shelf.config').cache_file, 'r')
  if not fh then
    return false, nil
  end
  local contents = fh:read '*a'
  local ok = false
  local data = nil
  if contents and #contents > 0 then
    data = vim.json.decode(contents)
    if data and data ~= vim.NIL and not vim.tbl_isempty(data) then
      ok = true
    end
  end
  fh:close()
  return ok, data
end

---@class shelf.types.data
---@field _read fun(self: shelf.types.data): boolean
function Data:_read()
  local cwd = vim.fn.getcwd()
  local ok, data = self:read_data()
  if ok and data and data.list[cwd] then
    local _added = {}
    for _, name in ipairs(self.data.list[cwd]) do
      _added[name] = true
    end
    for _, name in ipairs(data.list[cwd]) do
      if not _added[name] then
        self.data.list[cwd][#self.data.list[cwd] + 1] = name
      end
    end
  end

  return ok
end

---@class shelf.types.data
---@field read fun(self: shelf.types.data): boolean
function Data:read()
  local ok = self:_read()
  if ok then
    self:register_list()
  end

  return ok
end

---@class shelf.types.data
---@field fill fun(self: shelf.types.data): boolean
function Data:fill()
  local ok, data = self:read_data()
  if ok and data then
    self.data = vim.tbl_deep_extend('keep', self.data, data)
  end

  return ok
end

---@class shelf.types.data
---@field write fun(self: shelf.types.data)
function Data:write()
  self:sync_list()
  self:fill()
  local fh = io.open(require('shelf.config').cache_file, 'w+')
  if not fh then
    return
  end
  self:clean()
  local contents = vim.json.encode(self.data)
  fh:write(contents)
  fh:close()
end

---@class shelf.types.data
---@field clean fun(self: shelf.types.data)
function Data:clean()
  local cwd = vim.fn.getcwd()
  for i, name in ipairs(self.data.list[cwd]) do
    if string.len(name) == 0 then
      table.remove(self.data.list[cwd], i)
    end
  end
end

--- configure global data
--- - add new items from data to bufferlist
---@class shelf.types.data
---@field register_list fun(self: shelf.types.data)
function Data:register_list()
  local cwd = vim.fn.getcwd()
  require('shelf'):list():register(self.data.list[cwd])
end

--- configure local data
--- - call `bufferlist:update()`
--- - update local data list for cwd with bufferlist
---@class shelf.types.data
---@field sync_list fun(self: shelf.types.data)
function Data:sync_list()
  local cwd = vim.fn.getcwd()
  require('shelf'):list():update()
  self.data.list[cwd] = vim.tbl_map(function(item)
    return item[2]
  end, require('shelf'):list())
end

return Data:new()
