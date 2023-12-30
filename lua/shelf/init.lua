
local default_config = {
  mappings = {
    close = 'q',
    quit = '<esc>', -- close without applying changes
    cut = 'dd',
    paste = 'p',
    prepend = 'P',
    move_down = 'J',
    move_up = 'K',
    new = 'o',
    go_down = 'j',
    go_up = 'k',
  },
}

_G.shelf_config = vim.tbl_deep_extend('force', default_config, _G.shelf_config or {})

local M = {}

M.setup = function(config)
  _G.shelf_config = vim.tbl_deep_extend('force', _G.shelf_config, config)
end

return M
