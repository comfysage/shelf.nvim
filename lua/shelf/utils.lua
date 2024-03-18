local utils = {}

---@param name string
---@return integer
utils.create_buf = function(name)
  vim.notify(('creating buffer [%s]'):format(name), vim.log.levels.DEBUG)
  local nr = vim.fn.bufadd(name)
  vim.api.nvim_buf_call(nr, function()
    vim.cmd.buffer()
  end)

  return nr
end

return utils
