require 'shelf.bufferlist'

local default_config = {
  -- cache file where bufferlists are saved
  cache_file = vim.fn.stdpath 'data' .. '/shelf.cache.json',
  -- mappings for shelf ui
  mappings = {
    -- move up and down the list
    go_down = 'j',
    go_up = 'k',
    -- close the window
    close = 'q',
    -- close without applying changes
    quit = '<esc>',
    -- open current item
    open = '<cr>',
    -- cut item (so it can be pasted elsewhere in the list)
    cut = 'dd',
    paste = 'p',
    prepend = 'P',
    -- move current item one index down
    move_down = 'J',
    -- move current item one index up
    move_up = 'K',
    -- add a new item to the bufferlist
    create = 'a',
  },
  ui = {
    size = {
      -- size fields can be either an absolute integer size or a number between 0 and 1
      -- window is 90 characters wide
      width = 90,
      -- max window height is 90% of editor height
      height = 0.9,
    },
  },
}

_G.shelf_config = vim.tbl_deep_extend('force', default_config, _G.shelf_config or {})

local M = {}

M.read = function()
  require 'shelf.data':new():read()
end
M.write = function()
  require 'shelf.data':new():write()
end

M.setup = function(config)
  _G.shelf_config = vim.tbl_deep_extend('force', _G.shelf_config, config or {})

  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    once = true,
    callback = function(_)
      require 'shelf'.read()
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function(_)
      require 'shelf'.write()
    end,
  })
end

return M
