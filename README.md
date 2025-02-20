# Matrix Effect

Matrix Effect is a Neovim plugin that simulates the iconic falling green characters from *The Matrix*. It leverages Neovim’s floating windows, timers, and highlight APIs to create a dynamic, full-screen animation.

## Installation

Install using your favorite plugin manager.

### Using Lazy:

```lua
{ 'chanand/matrixeffect.nvim' }
```
## Usage

Once installed, you have several options to start the Matrix effect.

### Vim Command

The plugin creates a user command called `:StartMatrixEffect`. Open the command line in Neovim and run:

```vim
:StartMatrixEffect
```

### Lua API

You can also start the effect directly from Lua:

```lua
require("matrixeffect.nvim").start_matrix_effect()
```

### Key Mapping

For quick access, map the command to a key in your Neovim configuration. For example, to bind it to `<leader>m`:

```lua
vim.keymap.set("n", "<leader>m", require("matrixeffect.nvim").start_matrix_effect)
```

## Configuration

Currently, the plugin uses default settings for animation speed, color highlights, and other parameters. Future updates may include additional customization options. Feel free to fork and modify the code as needed!

## Contributing

Contributions are welcome! If you have suggestions, find bugs, or want to contribute new features, please open an issue or submit a pull request on the GitHub repository.

