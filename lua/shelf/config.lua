---@class shelf.types.config
---@field cache_file string
---@field mappings table<string, string>
---@field ui { size: table<'width'|'height', number> }
local Config = {}
Config.__index = Config

---@class shelf.types.config
---@field new fun(self: shelf.types.config): shelf.types.config
function Config:new()
  local config = setmetatable({
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
  }, self)

  return config
end

---@class shelf.types.config
---@field merge fun(self: shelf.types.config, cfg: shelf.types.config)
function Config:merge(cfg)
  self = vim.tbl_deep_extend('force', self, cfg or {})
end

_G.shelf_config = _G.shelf_config or Config:new()

return _G.shelf_config
