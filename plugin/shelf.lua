if vim.g.loaded_shelf then
  return
end

local min_version = "0.10.0"
if vim.fn.has("nvim-" .. min_version) ~= 1 then
  vim.notify_once(("shelf.nvim requires Neovim >= %s"):format(min_version), vim.log.levels.ERROR)
  return
end

vim.g.loaded_shelf = true


local group = vim.api.nvim_create_augroup('shelf', { clear = true })

if not vim.v.vim_did_enter then
  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    callback = function(_)
      require('shelf.data'):read()
    end,
  })
else
  require('shelf.data'):read()
end
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = group,
  callback = function(_)
    require('shelf.data'):write()
  end,
})
