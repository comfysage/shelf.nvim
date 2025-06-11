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
---@field get fun(self: shelf.types.bufferlist): shelf.types.bufferlist.list
function Bufferlist:get()
  return self.list
end

---@class shelf.types.bufferlist
---@field register fun(self: shelf.types.bufferlist, list: string[])
function Bufferlist:register(list)
  ---@type table<string, boolean>
  local exists = vim.iter(ipairs(self.list)):fold({}, function(acc, _, item)
    acc[item[2]] = true
    return acc
  end)

  vim.iter(ipairs(list)):each(function(_, name)
    if not exists[name] then
      self:append(name, vim.fn.bufnr(name))
    end
  end)
end

---@class shelf.types.bufferlist
---@field register_buffers fun(self: shelf.types.bufferlist)
function Bufferlist:register_buffers()
  local buflist = vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(bufnr)
      if vim.bo[bufnr].buftype ~= '' then
        return false
      end
      return vim.api.nvim_buf_is_loaded(bufnr)
        and vim.api.nvim_buf_is_valid(bufnr)
    end)
    :map(function(bufnr)
      return vim.api.nvim_buf_get_name(bufnr)
    end)
    :totable()

  self:register(buflist)
end

---@class shelf.types.bufferlist
---@field clean fun(self: shelf.types.bufferlist)
function Bufferlist:clean()
  self.list = vim
    .iter(ipairs(self.list))
    :map(function(_, item)
      local bufnr = item[1]
      -- check for connected items
      if bufnr >= 0 then
        -- check for broken connection
        if 1 ~= vim.fn.buflisted(item[1]) then
          return
        end
        if
          vim.api.nvim_get_option_value('buftype', { buf = item[1] })
          == 'nofile'
        then
          return
        end
      end
      local fname = item[2]
      if #fname == 0 then
        return
      end
      if fname:sub(1, 5) == '/tmp/' then
        return
      end
      return item
    end)
    :totable()
end

---@class shelf.types.bufferlist
---@field fix fun(self: shelf.types.bufferlist)
function Bufferlist:fix()
  self:clean()
  self.list = vim
    .iter(ipairs(self.list))
    :map(function(_, item)
      local bufnr = item[1]
      local fname = item[2]

      if bufnr < 0 then
        if require('shelf.config').get().restore_buffers then
          bufnr = utils.create_buf(fname)
        end
      else
        bufnr = vim.fn.bufnr(fname)
      end

      return { bufnr, fname }
    end)
    :totable()
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
    return -1
  end

  local i, _ = vim.iter(ipairs(self.list)):find(function(_, v)
    return (props.name and v[2] == props.name)
      or (props.buf and props.buf ~= -1 and v[1] == props.buf)
  end)
  if i then
    return i
  end

  return -1
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
---@field remove fun(self: shelf.types.bufferlist, name: string)
function Bufferlist:remove(name)
  local index = self:get_index { name = name }
  self:delete(index)
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

local M = {}

---@class shelf.types.bufferlist
M.bufferlist = Bufferlist:new()

return M
