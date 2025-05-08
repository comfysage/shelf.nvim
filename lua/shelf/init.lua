---@mod shelf

local config = require('shelf.config')

if vim.fn.has("nvim-0.10.0") ~= 1 then
    error("shelf requires Neovim >= 0.10.0")
end

require 'shelf.bufferlist'

local Shelf = {}
Shelf.__index = Shelf

function Shelf:new()
  local shelf = setmetatable({}, self)

  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    once = true,
    callback = function(_)
      require('shelf.data'):read()
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function(_)
      require('shelf.data'):write()
    end,
  })

  return shelf
end

---@param cfg? shelf.config
Shelf.setup = function(cfg)
  cfg = cfg or {}
  config.set(config.override(cfg))
  package.loaded['shelf'] = Shelf:new()
end

function Shelf:list()
  return require 'shelf.bufferlist'
end

return (package.loaded['shelf'] and type(package.loaded['shelf']) == 'table')
    and package.loaded['shelf']
  or Shelf:new()
