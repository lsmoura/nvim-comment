# comment.nvim

A simple way to add and remove comments from your codebase, without multi cursors

## Installation

### Lazy

```lua
return {
  "lsmoura/nvim-comment",
  config = function()
    local comment = require("comment")
    vim.keymap.set({ 'n', 'v' }, '<leader>/', comment.toggle, { desc = 'comment/uncomment current line or block' })
  end,
}
```

if you want to set your own comment blocks:

```lua
return {
  "lsmoura/nvim-comment",
  config = function()
    local comment = require("comment")
    comment.setup({ comments = { foo = "#" })
    vim.keymap.set({ 'n', 'v' }, '<leader>/', comment.toggle, { desc = 'comment/uncomment current line or block' })
  end
}
```

# author

- [Sergio Moura](https://sergio.moura.ca)

