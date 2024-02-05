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

  data:cfg_local()

  return data
end

---@class shelf.types.data
---@field read_data fun(self: shelf.types.data): boolean, shelf.types.data.value?
function Data:read_data()
  local fh = io.open(shelf_config.cache_file, 'r')
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
        self.data.list[cwd][#self.data.list[cwd]+1] = name
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
    self:cfg_global()
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
  self:cfg_local()
  self:fill()
  local fh = io.open(shelf_config.cache_file, 'w+')
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

---@class shelf.types.data
---@field _cfg fun(self: shelf.types.data)
function Data:_cfg()
  _G.bufferlist = _G.bufferlist or {}
end

--- configure global data
--- - add new items from data to bufferlist
--- - call `bufferlist:update()`
---@class shelf.types.data
---@field cfg_global fun(self: shelf.types.data)
function Data:cfg_global()
  self:_cfg()
  local cwd = vim.fn.getcwd()
  if self.data.list[cwd] then
    local _added = {}
    for _, item in ipairs(_G.bufferlist.list) do
      local name = item[2]
      _added[name] = true
    end
    for _, name in ipairs(self.data.list[cwd]) do
      if not _added[name] then
        _G.bufferlist.list[#_G.bufferlist.list+1] = { -1, name }
      end
    end
  end
  _G.bufferlist:update()
end

--- configure local data
--- - call `bufferlist:update()`
--- - update local data list for cwd with bufferlist
---@class shelf.types.data
---@field cfg_local fun(self: shelf.types.data)
function Data:cfg_local()
  self:_cfg()
  local cwd = vim.fn.getcwd()
  _G.bufferlist:update()
  self.data.list[cwd] = vim.tbl_map(function(item)
    return item[2]
  end, _G.bufferlist.list)
end

return Data
