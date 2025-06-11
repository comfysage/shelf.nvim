---@class shelf.config
---@field cache_file string
---@field restore_buffers boolean
---@field mappings table<string, string>
---@field ui { size: table<'width'|'height', number> }

local M = {}

M.default = {
  -- cache file where bufferlists are saved
  cache_file = vim.fn.stdpath 'state' .. '/shelf.list.json',
  -- enable persistent bufferlist
  restore_buffers = false,
  -- mappings for shelf ui
  mappings = {
    -- close the window
    close = 'q',
    -- close without applying changes
    quit = '<esc>',
    -- open current item
    open = '<cr>',
    -- apply buffer edits
    apply = '=',
    -- reset buffer edits
    reset = '<bs>',
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

---@type shelf.config
---@diagnostic disable-next-line: missing-fields
M.config = {}

---@return shelf.config
function M.get()
  return vim.tbl_deep_extend('force', M.default, M.config)
end

---@param cfg shelf.config
---@return shelf.config
function M.override(cfg)
  return vim.tbl_deep_extend('force', M.default, cfg)
end

---@param cfg shelf.config
function M.set(cfg)
  M.config = cfg
end

function M.validate()
  vim.validate('cfg', M.get(), function(cfg)
    vim.validate('cfg.cache_file', cfg.cache_file, 'string')
    vim.validate('cfg.restore_buffers', cfg.restore_buffers, 'boolean')
    vim.validate('cfg.mappings', cfg.mappings, function(v)
      return vim.iter(pairs(v)):all(function(n, k)
        vim.validate('cfg.mappings.' .. n, k, 'string')
        return true
      end)
    end)
    vim.validate('cfg.ui', cfg.ui, function(ui)
      vim.validate('cfg.ui.size', ui.size, function(size)
        vim.validate('cfg.ui.size.width', size.width, 'number')
        vim.validate('cfg.ui.size.height', size.height, 'number')
        return true
      end)
      return true
    end)
    return true
  end)
end

return M
