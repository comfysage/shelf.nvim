local config = require 'shelf.config'

local ui = {}

local api = vim.api

local function not_empty(v)
  return vim.fn.empty(v) ~= 1
end

local has_yosu, _ = pcall(require, 'yosu')
if not has_yosu then
  return error('shelf requires yosu.nvim')
end

local model = require 'yosu.model'({
  bufferlist = require 'shelf.bufferlist',
  -- list as drawn lines
  lines = {},
  -- list as edited state
  state = {},
}, {
  title = 'bufferlist',
  persistent = true,
  text_edit = true,
  size = {
    width = config.get().ui.size.width,
    height = config.get().ui.size.height,
  },
})

function model:init()
  self.data.bufferlist:update()
  self:send 'reset_state'
  self:on('ModeChanged', function(props)
    if props.match == 'i:n' then
      self:send 'text_changed'
    end
  end, {})

  local cfg = config.get()

  self:add_mapping('n', 'q', 'close')
  self:add_mapping('n', cfg.mappings.close, 'close')
  self:add_mapping('n', cfg.mappings.quit, 'quit')
  self:add_mapping('n', cfg.mappings.open, 'open')
  self:add_mapping('n', cfg.mappings.apply, 'apply_state')
  self:add_mapping('n', cfg.mappings.reset, 'reset_state')

  self:send 'opts'
end

local function draw(v)
  local name = v[2]
  local line =
  string.gsub(name, string.format('^%s', vim.fn.getcwd() .. '/'), '')

  return line
end

function model:view()
  local lines = vim.iter(self.data.state):map(draw):totable()
  self.data.lines = lines
  self:send 'fix_winheight'
  return lines
end

---@param props core.types.ui.model
---@return integer
local function get_current_index(props)
  local pos = api.nvim_win_get_cursor(props.internal.win)
  return pos[1]
end

---@param props core.types.ui.model
---@return boolean
local function has_changes(props)
  local function get_second(array)
    return array[2]
  end
  local current_list = vim.iter(props.data.bufferlist.list):map(get_second):filter(not_empty):map(function(path)
    local repl = string.gsub(path, vim.fn.getcwd() .. '/', '')
    return repl
  end):totable()
  local next_list = vim.iter(props.data.lines):filter(not_empty):totable()
  local current = vim.iter(current_list):join('\n')
  local next = vim.iter(next_list):join('\n')

  ---@diagnostic disable-next-line: missing-fields
  local diff = vim.diff(current, next, {
    result_type = 'indices',
    ignore_whitespace = true,
    ignore_whitespace_change = true,
    ignore_whitespace_change_at_eol = true,
    ignore_cr_at_eol = true,
    ignore_blank_lines = true,
  })

  return #diff > 0
end

---@param props core.types.ui.model
local function state_diff(props)
  local function get_second(array)
    return array[2]
  end
  local current_list = vim.iter(props.data.bufferlist.list):map(get_second):filter(not_empty):totable()
  local next_list = vim.iter(props.data.state):map(get_second):filter(not_empty):totable()
  local current = vim.iter(current_list):join('\n')
  local next = vim.iter(next_list):join('\n')

  local diff = {}
  ---@param tag boolean
  ---@param name string
  local function guess(tag, name)
    ---@type boolean?
    local _tag = tag
    if diff[name] == false and tag then
      _tag = nil
    end
    if diff[name] and not tag then
      _tag = nil
    end
    diff[name] = _tag
  end

  ---@diagnostic disable-next-line: missing-fields
  vim.diff(current, next, {
    on_hunk = function(start_cur, count_cur, start_next, count_next)
      if count_next < count_cur then
        local _start = start_cur
        local _end = _start + count_cur - 1
        vim.iter(current_list):slice(_start, _end):each(function(item)
          guess(false, item)
        end)
      end
      if start_cur == start_next and count_cur == count_next then
        local _start = start_cur
        local _end = _start + count_cur - 1
        vim.iter(current_list):slice(_start, _end):each(function(item)
          guess(false, item)
        end)
        vim.iter(next_list):slice(_start, _end):each(function(item)
          guess(true, item)
        end)
      end
      if count_next > count_cur and count_cur == 0 then
        -- added items
        vim.iter(next_list):slice(start_next, start_next+count_next-1):each(function(item)
          guess(true, item)
        end)
      end
    end,
    ignore_whitespace = true,
    ignore_whitespace_change = true,
    ignore_whitespace_change_at_eol = true,
    ignore_cr_at_eol = true,
    ignore_blank_lines = true,
  })
  return diff
end

function model:update(msg)
  local fn = {
    -- fix winheight; adjust based on # of lines
    fix_winheight = function()
      local win_config = self.internal.window.config
      local winheight = self.internal.window.height
      local nr_lines = math.max(#self.data.lines, 1)
      local next = math.min(winheight, nr_lines)

      win_config.row = math.floor((winheight - next) / 2)
      win_config.height = next

      self.internal.window.config = win_config
      api.nvim_win_set_config(self.internal.win, self.internal.window.config)
    end,
    fix_modified_hl = function()
      local is_changed = has_changes(self)
      if is_changed then
        vim.wo[self.internal.win].winhl = 'FloatBorder:DiagnosticFloatingWarn'
      else
        vim.wo[self.internal.win].winhl = 'FloatBorder:FloatBorder'
      end
    end,
    show = function()
      self:send 'opts'
      self.data.bufferlist:update()
      self:send 'reset_state'
      return true
    end,
    opts = function()
      api.nvim_set_option_value('number', true, { win = self.internal.win })
    end,
    apply_state = function ()
      -- apply state
      self:send 'update_state'
      self.data.bufferlist.list = self.data.state
      local diff = state_diff(self)

      vim.iter(pairs(diff)):each(function(name, tag)
        if tag then
          -- add item
          vim.notify('add buffer '..name, vim.log.levels.DEBUG)
          self.data.bufferlist:append(name)
        else
          -- delete item
          vim.notify('delete buffer '..name, vim.log.levels.DEBUG)
          self.data.bufferlist:remove(name)
        end
      end)
      self.data.bufferlist:update()
      self:send 'fix_modified_hl'
    end,
    update_state = function()
      -- update state based on lines
      self.data.state = vim.iter(self.data.lines):filter(not_empty):map(function(item)
        if string.sub(item, 1, 1) ~= '/' then
          item = string.format('%s/%s', vim.fn.getcwd(), item)
        end
        return item
      end):map(function(item)
        return { -1, item }
      end):totable()
    end,
    reset_state = function()
      -- reset edits
      self.data.state = self.data.bufferlist.list
      return true
    end,
    text_changed_insert = function ()
      self:send 'text_changed'
    end,
    text_changed = function()
      self.data.lines = api.nvim_buf_get_lines(self.internal.buf, 0, -1, false)
      self:send 'fix_winheight'
      self:send 'fix_modified_hl'
    end,
    open = function()
      local index = get_current_index(self)
      if index == 0 then
        return
      end

      self:send 'close'

      self.data.bufferlist:open(index)
    end,
    create = function()
      vim.ui.input({ prompt = 'file:' }, function(input)
        if not input or string.len(input) == 0 then
          return
        end
      end)
    end,
    close = function()
      self:send 'apply_state'

      _G.bufferlist = self.data.bufferlist

      vim.cmd.quit()
    end,
  }

  if not fn[msg] or type(fn[msg]) ~= 'function' then
    return
  end
  return fn[msg]()
end

ui.open = function()
  model:open()
  return model
end

return ui
