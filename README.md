# Log.nvim

A Neovim plugin for aggregating and viewing code comments (todos, notes, logs, etc.) from across your project.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'your-username/log.nvim',
  config = function()
    require('log').setup({
      -- Optional configuration
      patterns = { 'TODO:', 'FIXME:', 'NOTE:', 'LOG:' },
      window = {
        position = 'right',
        width = 60,
      }
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'your-username/log.nvim',
  config = function()
    require('log').setup()
  end
}
```

## Usage

### Commands

- `:LogShow` - Open the log comments window
- `:LogScan` - Manually scan project for log comments
- `:LogToggle` - Toggle the log window open/closed

### Keymaps (in log window)

- `q` - Close the log window
- `r` - Refresh/rescan the project
- `<CR>` - Jump to the source file (coming soon)

### Example Comments

The plugin will automatically detect comments like:

```lua
-- TODO: Refactor this function to be more efficient
-- FIXME: Handle edge case when user is nil
-- NOTE: This is a temporary workaround
-- LOG: Added new authentication method
-- IDEA: Could use caching here for better performance
```

## Configuration

Default configuration:

```lua
require('log').setup({
  -- Comment patterns to search for
  patterns = {
    'TODO:', 'FIXME:', 'NOTE:', 'LOG:', 'IDEA:', 'HACK:', 'BUG:'
  },
  
  -- File extensions to scan
  file_extensions = {
    'lua', 'py', 'js', 'ts', 'go', 'rs', 'c', 'cpp', 'h', 'hpp',
    'java', 'rb', 'php', 'sh', 'vim', 'md', 'txt'
  },
  
  -- Directories to exclude from scanning
  exclude_dirs = {
    'node_modules', '.git', 'target', 'build', 'dist', '__pycache__'
  },
  
  -- Window configuration
  window = {
    position = 'right',  -- 'left', 'right', 'top', 'bottom'
    width = 60,          -- Width for left/right positions
    height = 20,         -- Height for top/bottom positions
  },
  
  -- Auto-refresh when files are saved
  auto_refresh = true,
  
  -- Display options
  show_line_numbers = true,
  show_file_paths = true,
})
```

## File Structure

```
log.nvim/
├── plugin/
│   └── log.lua              # Plugin entry point
├── lua/
│   └── log/
│       ├── init.lua         # Main module
│       ├── config.lua       # Configuration management
│       ├── scanner.lua      # File scanning logic
│       └── ui.lua           # User interface
├── README.md
└── LICENSE
```

## Roadmap

- [x] Basic comment scanning
- [x] Simple UI display
- [x] Auto-refresh on file save
- [ ] Jump to source file from log window
- [ ] Filter by comment type
- [ ] Search within logs
- [ ] Telescope integration
- [ ] Custom comment formats
- [ ] Git integration (show last modified)

## Contributing

Feel free to submit issues and enhancement requests!

---

## Quick Start Example

1. Create a new directory for your plugin:
```bash
mkdir -p ~/.local/share/nvim/site/pack/plugins/start/log.nvim
cd ~/.local/share/nvim/site/pack/plugins/start/log.nvim
```

2. Copy the plugin files from the artifact above into the appropriate directories

3. Add to your Neovim config:
```lua
-- In your init.lua or init.vim
require('log').setup()

-- Optional: Set up keybindings
vim.keymap.set('n', '<leader>ls', ':LogShow<CR>', { desc = 'Show logs' })
vim.keymap.set('n', '<leader>lt', ':LogToggle<CR>', { desc = 'Toggle logs' })
```

4. Test it out:
   - Add some TODO comments to your code
   - Run `:LogShow` to see them aggregated
   - Use `r` in the log window to refresh

That's it! Your MVP is ready to use.
