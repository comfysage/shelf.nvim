# shelf

:books: a bookmarks manager for chaivim.

## :sparkles: Features

similar to [harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2).

## :lock: requirements

- Neovim `>= 0.9.0` (needs to be built with LuaJIT)
- [chaivim](https://github.com/crispybaccoon/chaivim)

## :package: installation

shelf can be installed by adding *this* to your `lua/plugins/init.lua`.
```lua
{
    'crispybaccoon/shelf.nvim',
    opts = {},
    config = function(_, opts)
        require 'shelf'.setup(opts)

        -- toggle shelf ui
        keymaps.normal['<leader>p'] = {
            function()
                require('shelf.ui').open()
            end,
            'show bufferlist',
        }
    end,
}
```

## :gear: configuration

below is the default shelf configuration.
```lua
{
    opts = {
        -- cache file where bufferlists are saved
        cache_file = vim.fn.stdpath 'data' .. '/shelf.cache.json',
        -- mappings for shelf ui
        mappings = {
            -- move up and down the list
            go_down = 'j',
            go_up = 'k',
            -- close the window
            close = 'q',
            -- close without applying changes
            quit = '<esc>',
            -- open current item
            open = '<cr>',
            -- cut item (so it can be pasted elsewhere in the list)
            cut = 'dd',
            paste = 'p',
            prepend = 'P',
            -- move current item one index down
            move_down = 'J',
            -- move current item one index up
            move_up = 'K',
            -- add a new item to the bufferlist
            create = 'a',
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
