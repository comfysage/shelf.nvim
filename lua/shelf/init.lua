---@mod shelf

local config = require('shelf.config')

local M = {}

---@param cfg? shelf.config
M.setup = function(cfg)
  cfg = cfg or {}
  config.set(config.override(cfg))
  config.validate()
end

M.init = function()
  require('shelf.data'):read()
  require('shelf.bufferlist').bufferlist:fix()
end

return M
