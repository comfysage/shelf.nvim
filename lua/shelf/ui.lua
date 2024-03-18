local config = require 'shelf.config'

local ui = {}

local api = vim.api

local model = require 'core.ui'({
  bufferlist = require 'shelf.bufferlist',
  lines = { 0 },
}, {
  title = 'bufferlist',
  persistent = true,
  size = {
    width = config.ui.size.width,
    height = config.ui.size.height,
  },
})

function model:init()
  self:send 'reset_state'

  -- reset movement keys
  for _, k in ipairs { 'h', 'j', 'k', 'l', '<left>', '<down>', '<up>', '<right>' } do
    vim.keymap.set('n', k, '', { buffer = self.internal.buf })
  end

  self:add_mapping('n', 'q', 'close')
  self:add_mapping('n', config.mappings.close, 'close')
  self:add_mapping('n', config.mappings.quit, 'quit')
  self:add_mapping('n', config.mappings.open, 'open')
  self:add_mapping('n', config.mappings.cut, 'cut')
  self:add_mapping('n', config.mappings.paste, 'paste')
  self:add_mapping('n', config.mappings.prepend, 'prepend')
  self:add_mapping(
    'n',
    config.mappings.move_down,
    'move_down'
  )
  self:add_mapping('n', config.mappings.move_up, 'move_up')
  self:add_mapping('n', config.mappings.create, 'create')
  self:add_mapping('n', config.mappings.go_down, 'go_down')
  self:add_mapping('n', config.mappings.go_up, 'go_up')

  self:send 'opts'
end

function model:view()
  local function draw(index)
    local v = self.data.bufferlist.list[index]
    local name = v[2]
    local line =
      string.gsub(name, string.format('^%s', vim.fn.getcwd() .. '/'), '')

    return line
  end
  local lines = {}
  for i, _ in ipairs(self.data.bufferlist.list) do
    if i ~= self.data.bufferlist__cut then
      lines[#lines + 1] = draw(i)
    end
  end

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
---@param index integer
local function paste(props, index)
  -- account for moving the value to a new position while the old one still exists
  if index > props.data.bufferlist__cut then
    index = index - 1
  end

  props.data.bufferlist:move(props.data.bufferlist__cut, index)

  props.data.bufferlist__cut = 0
end
---@param props core.types.ui.model
---@param rel integer
local cursor_go = function(props, rel)
  local pos = api.nvim_win_get_cursor(props.internal.win)
  pos[1] = pos[1] + rel
  local lines = props.data.lines
  if pos[1] < 1 or pos[1] > #lines then
    return
  end
  api.nvim_win_set_cursor(props.internal.win, pos)
end

function model:update(msg)
  local fn = {
    -- fix winheight; adjust based on # of lines
    fix_winheight = function()
      local win_config = self.internal.window.config
      local winheight = self.internal.window.height
      local _height = self.internal.window.config.height
      local nr_lines = math.max(#self.data.lines, 1)
      _height = nr_lines > _height and _height or nr_lines

      win_config.row = math.floor((winheight - _height) / 2)
      win_config.height = _height

      self.internal.window.config = win_config
      api.nvim_win_set_config(self.internal.win, self.internal.window.config)
    end,
    show = function()
      self:send 'opts'
      self.data.bufferlist:update()
      return true
    end,
    opts = function()
      api.nvim_set_option_value('number', true, { win = self.internal.win })
    end,
    reset_state = function()
      self.data.bufferlist__cut = 0
    end,
    check_delete = function()
      if self.data.bufferlist__cut > 0 then
        vim.notify(
          string.format('delete cut item [%d]', self.data.bufferlist__cut),
          vim.log.levels.DEBUG
        )
        self.data.bufferlist:delete(self.data.bufferlist__cut)
        self:send 'reset_state'
      end
    end,
    cut = function()
      self:send 'check_delete'

      local index = get_current_index(self)
      if index == 0 then
        return
      end
      self.data.bufferlist__cut = index
      return true
    end,
    paste = function()
      if self.data.bufferlist__cut == 0 then
        return
      end
      local new_index = get_current_index(self) + 1

      paste(self, new_index)
      return true
    end,
    go_down = function()
      cursor_go(self, 1)
    end,
    go_up = function()
      cursor_go(self, -1)
    end,
    move_down = function()
      local cur = get_current_index(self)
      self.data.bufferlist:move(cur, cur + 1)

      self:send 'go_down'
      return true
    end,
    move_up = function()
      local cur = get_current_index(self)
      self.data.bufferlist:move(cur, cur - 1)

      self:send 'go_up'
      return true
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
        if string.sub(input, 1, 1) ~= '/' then
          input = string.format('%s/%s', vim.fn.getcwd(), input)
        end
        self.data.bufferlist:append(input)
        self:send 'view'
      end)
    end,
    close = function()
      self:send 'check_delete'

      _G.bufferlist = self.data.bufferlist

      vim.cmd.quit()
    end,
    prepend = function()
      self:send 'paste'
      self:send 'move_up'
      return true
    end,
  }

  if not fn[msg] or type(fn[msg]) ~= 'function' then
    return
  end
  return fn[msg]()
end

ui.open = function()
  model:open()
end

return ui
