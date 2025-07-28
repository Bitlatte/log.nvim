local config = require('log.config')

local M = {}

local buf = nil
local win = nil

function M.open(logs)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  
  -- Create buffer
  buf = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'log')
  vim.api.nvim_buf_set_name(buf, 'Log Comments')
  
  -- Create window
  local cfg = config.get()
  local width = cfg.window.width
  local height = cfg.window.height
  
  if cfg.window.position == 'right' then
    vim.cmd('vertical rightbelow ' .. width .. 'new')
  elseif cfg.window.position == 'left' then
    vim.cmd('vertical leftabove ' .. width .. 'new')
  elseif cfg.window.position == 'top' then
    vim.cmd('horizontal leftabove ' .. height .. 'new')
  else
    vim.cmd('horizontal rightbelow ' .. height .. 'new')
  end
  
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  
  -- Set window options
  vim.api.nvim_win_set_option(win, 'number', cfg.show_line_numbers)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)
  vim.api.nvim_win_set_option(win, 'wrap', false)
  
  -- Populate buffer
  M._populate_buffer(logs)
  
  -- Set up keymaps
  M._setup_keymaps()
end

function M._populate_buffer(logs)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local lines = {}
  local cfg = config.get()
  
  if #logs == 0 then
    lines = { 'No log comments found!' }
  else
    table.insert(lines, 'Log Comments (' .. #logs .. ' found)')
    table.insert(lines, string.rep('=', 50))
    table.insert(lines, '')
    
    local current_file = nil
    for i, log in ipairs(logs) do
      -- Add file header if this is a new file
      if log.file ~= current_file then
        if current_file then
          table.insert(lines, '')
        end
        current_file = log.file
        local rel_path = vim.fn.fnamemodify(log.file, ':.')
        table.insert(lines, '📁 ' .. rel_path)
        table.insert(lines, string.rep('-', #rel_path + 3))
      end
      
      -- Add log entry
      local line_text = string.format('  [%s:%d] %s %s',
        vim.fn.fnamemodify(log.file, ':t'),
        log.line,
        log.pattern,
        log.text:sub(#log.pattern + 2)
      )
      table.insert(lines, line_text)
    end
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M._setup_keymaps()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local opts = { buffer = buf, silent = true }
  
  -- Close window
  vim.keymap.set('n', 'q', function()
    require('log').hide_logs()
  end, opts)
  
  -- Refresh
  vim.keymap.set('n', 'r', function()
    local logs = require('log').scan_project()
    M.refresh(logs)
  end, opts)
  
  -- Jump to file (placeholder for now)
  vim.keymap.set('n', '<CR>', function()
    -- TODO: Implement jump to file functionality
    print('Jump to file not implemented yet')
  end, opts)
end

function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
end

function M.focus()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end

function M.refresh(logs)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    M._populate_buffer(logs)
  end
end

return M
