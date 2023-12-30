local ui = {}

function ui.open()
  local bufferlist = require 'shelf.bufferlist'

  local bufnr = vim.api.nvim_create_buf(false, true)

  -- open window
  local winheight = vim.api.nvim_win_get_height(0)
  local winwidth = vim.opt.columns._value

  local _height = math.floor(winheight * .8)
  _height = #bufferlist.list > _height and _height or #bufferlist.list
  local _width = 64
  _width = _width > winwidth and winwidth or _width

  local win_config = {
    relative = 'win',
    title = 'bufferlist',
    title_pos = 'center',
    border = 'rounded',
    row = math.floor((winheight - _height) / 2),
    col = math.floor((winwidth - _width) / 2),
    width = _width,
    height = _height,
    hide = true,
  }
  local win = vim.api.nvim_open_win(bufnr, true, win_config)

  -- set up bufferlist

  local lines = {}

  local function draw(index)
    local v = bufferlist.list[index]
    local line = string.format('%d %s', v[1], v[2])

    return line
  end

  local function reset_lines()
    lines = {}
    for i, _ in ipairs(bufferlist.list) do
      lines[#lines + 1] = draw(i)
    end
  end

  local function update_lines()
    vim.api.nvim_set_option_value('modifiable', true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })
  end

  ---@return integer
  local function get_current_index()
    local pos = vim.api.nvim_win_get_cursor(win)
    return pos[1]
  end

  local bufferlist__cut = 0

  local function paste(index)
    -- account for moving the value to a new position while the old one still exists
    if index > bufferlist__cut then
      index = index - 1
    end

    bufferlist:move(bufferlist__cut, index)
    reset_lines()
    update_lines()

    bufferlist__cut = 0
  end

  -- mappings
  local mappings = {}
  mappings.cut = function()
    local index = get_current_index()
    if index == 0 then return end
    bufferlist__cut = index
    table.remove(lines, index)
    update_lines()
  end
  mappings.paste = function()
    if bufferlist__cut == 0 then
      return
    end
    local new_index = get_current_index() + 1

    paste(new_index)
  end
  mappings.close = function()
    if bufferlist__cut > 0 then
      vim.notify(string.format('delete cut item [%d]', bufferlist__cut), vim.log.levels.DEBUG)
      bufferlist:delete(bufferlist__cut)
    end

    _G.bufferlist = bufferlist

    vim.cmd.quit()
  end

  local cursor_go = function(rel)
    local pos = vim.api.nvim_win_get_cursor(win)
    pos[1] = pos[1] + rel
    if pos[1] < 1 or pos[1] > win_config.height then return end
    vim.api.nvim_win_set_cursor(win, pos)
  end
  mappings.go_down = function ()
    cursor_go(1)
  end
  mappings.go_up = function ()
    cursor_go(-1)
  end

  mappings.move_down = function ()
    mappings.cut()
    paste(get_current_index()+1)

    mappings.go_down()
  end
  mappings.move_up = function ()
    mappings.cut()
    paste(get_current_index()-2)

    mappings.go_up()
  end

  mappings.open = function ()
    local index = get_current_index()
    if index == 0 then return end

    vim.cmd.quit()

    bufferlist:open(index)
  end

  local opts = { buffer = bufnr, silent = true, noremap = true }

  -- reset movement keys
  for _, k in ipairs({'h','j','k','l', '<left>', '<down>', '<up>', 'right'}) do
    vim.keymap.set('n', k, '', { buffer = bufnr })
  end

  vim.keymap.set('n', 'q', mappings.close, opts)
  vim.keymap.set('n', bufferlist.config.mappings.close, mappings.close, opts)
  vim.keymap.set('n', bufferlist.config.mappings.quit, vim.cmd.quit, opts)
  vim.keymap.set('n', bufferlist.config.mappings.open, mappings.open, opts)
  vim.keymap.set('n', bufferlist.config.mappings.cut, mappings.cut, opts)
  vim.keymap.set('n', bufferlist.config.mappings.paste, mappings.paste, opts)
  vim.keymap.set('n', bufferlist.config.mappings.prepend, function()
    mappings.paste()
    mappings.move_up()
  end, opts)
  vim.keymap.set('n', bufferlist.config.mappings.move_down, mappings.move_down, opts)
  vim.keymap.set('n', bufferlist.config.mappings.move_up, mappings.move_up, opts)
  vim.keymap.set('n', bufferlist.config.mappings.new, mappings.cut, opts)
  vim.keymap.set('n', bufferlist.config.mappings.go_down, mappings.go_down, opts)
  vim.keymap.set('n', bufferlist.config.mappings.go_up, mappings.go_up, opts)

  reset_lines()
  update_lines()

  vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })

  win_config.hide = false
  vim.api.nvim_win_set_config(win, win_config)
end

return ui
