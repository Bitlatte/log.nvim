local M = {}

local default_config = {
  -- Log patterns to search for
  patterns = {
    'TODO:',
    'FIXME:',
    'NOTE:',
    'LOG:',
    'IDEA:',
    'HACK:',
    'BUG:',
  },
  
  -- File extensions to scan
  file_extensions = {
    'lua', 'py', 'js', 'ts', 'go', 'rs', 'c', 'cpp', 'h', 'hpp',
    'java', 'rb', 'php', 'sh', 'vim', 'md', 'txt'
  },
  
  -- Directories to exclude
  exclude_dirs = {
    'node_modules', '.git', 'target', 'build', 'dist', '__pycache__',
    '.pytest_cache', '.mypy_cache', 'vendor'
  },
  
  -- Comment patterns for different file types
  -- Can be a string for single-line, or a table of strings for multiple patterns (e.g., for multi-line comments)
  comment_patterns = {
    default = '//', -- Fallback for unknown file types
    lua = '--',
    python = '#',
    javascript = '//',
    typescript = '//',
    go = '//',
    rust = '//',
    c = '//',
    cpp = '//',
    java = '//',
    php = '//',
    sh = '#',
    bash = '#',
    ruby = '#',
    perl = '#',
    vim = '"',
    markdown = '<!--',
    html = {'<!--', '-->'},
    xml = {'<!--', '-->'},
    css = {'/%*', '*%/'},
  },
  
  -- UI settings
  window = {
    position = 'right',  -- 'left', 'right', 'top', 'bottom'
    width = 60,
    height = 20,
  },
  
  -- Auto-refresh on file save
  auto_refresh = true,
  
  -- Show line numbers in log view
  show_line_numbers = true,
  
  -- Show file paths in log view
  show_file_paths = true,

  -- Output format
  output_format = 'window', -- 'window', 'quickfix', or 'buffer'
}

local config = {}

function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})
end

function M.get()
  return config
end

return M
