require 'shelf.bufferlist'

local default_config = {
  cache_file = vim.fn.stdpath 'data' .. '/shelf.cache.json',
  mappings = {
    close = 'q',
    quit = '<esc>', -- close without applying changes
    open = '<cr>',
    cut = 'dd',
    paste = 'p',
    prepend = 'P',
    move_down = 'J',
    move_up = 'K',
    create = 'a',
    go_down = 'j',
    go_up = 'k',
  },
  ui = {
    size = {
      width = 90,
      height = 0.8,
    },
  },
}

_G.shelf_config = vim.tbl_deep_extend('force', default_config, _G.shelf_config or {})

local M = {}

M.read = function()
  require 'shelf.data':new()
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
