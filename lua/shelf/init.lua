---@mod shelf

local config = require('shelf.config')

local M = {}

---@param cfg? shelf.config
M.setup = function(cfg)
  cfg = cfg or {}
  config.set(config.override(cfg))
  config.validate()
end

return M
