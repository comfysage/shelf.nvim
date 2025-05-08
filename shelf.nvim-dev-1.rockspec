rockspec_format = "3.0"
package = "shelf.nvim"
version = "dev-1"
source = {
   url = "git://github.com/comfysage/" .. package,
}
description = {
   summary = "a bookmarks manager for chaivim.",
   detailed = [[
     a bookmarks manager for chaivim.
   ]],
   homepage = "https://github.com/comfysage/" .. package,
   labels = { 'neovim' },
   license = "GPL3"
}
build = {
  type = 'builtin',
  copy_directories = {
    'doc'
  }
}
dependencies = {
  'lua >= 5.1',
  'yosu.nvim',
}
