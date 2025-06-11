local utils = {}

---@param name string
---@return integer
utils.create_buf = function(name)
  local nr = vim.fn.bufadd(name)
  vim.api.nvim_set_option_value('buflisted', true, { buf = nr })
  vim.api.nvim_buf_call(nr, function()
    vim.cmd.buffer()
  end)

  return nr
end

return utils
