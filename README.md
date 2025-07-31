# shelf

:books: a bookmarks manager for chaivim.

<!-- TODO: add vhs tape -->

## :sparkles: Features

<!-- TODO: add detailed feature description -->

open the bufferlist:

```lua
require('shelf.ui').open()
```

make changes by editing the buffer, apply them with <kbd>=</kbd> or quit
without saving changes with <kbd>esc</kbd>.
the currently highlighted list item can be opened with <kbd>enter</kbd> or:

```lua
bufferlist:open(1) -- open item at index 1
```

## :lock: requirements

- Neovim `>= 0.10.0`
- [yosu.nvim](https://github.com/comfysage/yosu.nvim)

## :package: installation

shelf can be installed by adding _this_ to your `lua/plugins/init.lua`.

```lua
{
    'comfysage/shelf.nvim',
    dependencies = {'comfysage/yosu.nvim'},
    opts = {},
    config = function(_, opts)
        require 'shelf'.setup(opts)

        -- toggle shelf ui
        vim.keymap.set('n', '<leader>p', '<Plug>(shelf-open)', { silent = true })
    end,
}
```

## :gear: configuration

below is the default shelf configuration.

```lua
{
    opts = {
        -- cache file where bufferlists are saved
        cache_file = vim.fn.stdpath 'state' .. '/shelf.list.json',
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
}
```

## credits

the project was mainly inspired by
[harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2) and the keymap
behavior was inspired by
[mini.files](https://github.com/echasnovski/mini.files)
