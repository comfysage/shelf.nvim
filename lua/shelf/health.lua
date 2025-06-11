local health = {}

health.check = function()
  vim.health.start 'shelf.nvim - dependencies'

  local has_yosu, _ = pcall(require, 'yosu')
  if not has_yosu then
    vim.health.error 'shelf requires yosu.nvim'
  else
    vim.health.ok 'yosu.nvim found'
  end

  vim.health.start 'shelf.nvim - config'
  local cfg_ok, cfg_error = pcall(require('shelf.config').validate)
  if not cfg_ok then
    vim.health.error('config is invalid:\n\t' .. cfg_error)
  else
    vim.health.ok 'config is valid'
  end
end

return health
