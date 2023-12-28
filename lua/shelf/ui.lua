local ui = {}

function ui.open()
  local bufferlist = require 'shelf.bufferlist'

  local bufnr = vim.api.nvim_create_buf(false, true)

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
    local line = vim.api.nvim_get_current_line()
    local _line = vim.split(line, ' ')
    if #_line == 0 then return 0 end
    local _nr = _line[1]
    local nr = tonumber(_nr)
    local index = bufferlist:get_index { buf = nr }
    return index
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

  mappings.move_down = function ()
    mappings.cut()
    paste(get_current_index()+1)

    vim.cmd [[ norm! j ]]
  end
  mappings.move_up = function ()
    mappings.cut()
    paste(get_current_index()-2)

    vim.cmd [[ norm! k ]]
  end

  local opts = { buffer = bufnr, silent = true, noremap = true }

  vim.keymap.set('n', 'q', mappings.close, opts)
  vim.keymap.set('n', bufferlist.config.mappings.close, mappings.close, opts)
  vim.keymap.set('n', bufferlist.config.mappings.quit, vim.cmd.quit, opts)
  vim.keymap.set('n', bufferlist.config.mappings.cut, mappings.cut, opts)
  vim.keymap.set('n', bufferlist.config.mappings.paste, mappings.paste, opts)
  vim.keymap.set('n', bufferlist.config.mappings.prepend, function()
    mappings.paste()
    mappings.move_up()
  end, opts)
  vim.keymap.set('n', bufferlist.config.mappings.move_down, mappings.move_down, opts)
  vim.keymap.set('n', bufferlist.config.mappings.move_up, mappings.move_up, opts)
  vim.keymap.set('n', bufferlist.config.mappings.new, mappings.cut, opts)

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
  }

  reset_lines()
  update_lines()

  vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })

  local win = vim.api.nvim_open_win(bufnr, true, win_config)
end

return ui
