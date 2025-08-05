if vim.g.loaded_shelf then
  return
end

local min_version = '0.10.0'
if vim.fn.has('nvim-' .. min_version) ~= 1 then
  vim.api.nvim_echo(
    { { ('shelf.nvim requires Neovim >= %s'):format(min_version) } },
    true,
    { err = true }
  )
  return
end

vim.g.loaded_shelf = true

vim.keymap.set('n', '<Plug>(shelf-open)', function()
  require('shelf.ui').open()
end, { silent = true })

local group = vim.api.nvim_create_augroup('shelf', { clear = true })

if vim.v.vim_did_enter ~= 0 then
  require('shelf').init()
else
  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    callback = function(_)
      require('shelf').init()
    end,
  })
end
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = group,
  callback = function(_)
    require('shelf.data'):write()
  end,
})
