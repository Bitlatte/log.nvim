local config = require('log.config')

local M = {}

local buf = nil
local win = nil
local log_data = {}

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
  log_data = {}
  
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
          log_data[#lines] = nil -- Empty line, no jump target
        end
        current_file = log.file
        local rel_path = vim.fn.fnamemodify(log.file, ':.')
        table.insert(lines, '📁 ' .. rel_path)
        log_data[#lines] = { file = log.file, line = 1, is_header = true } -- File header
        table.insert(lines, string.rep('-', #rel_path + 3))
        log_data[#lines] = nil -- Separator line, no jump target
      end
      
      -- Add log entry
      local line_text = string.format('  [%s:%d] %s %s',
        vim.fn.fnamemodify(log.file, ':t'),
        log.line,
        log.pattern,
        log.text:sub(#log.pattern + 2)
      )
      table.insert(lines, line_text)
      -- Store log data for this line
      log_data[#lines] = {
        file = log.file,
        line = log.line,
        pattern = log.pattern,
        text = log.text,
        is_header = false
      }
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
  
  -- Jump to file
  vim.keymap.set('n', '<CR>', function()
    M._jump_to_file()
  end, opts)
  
  -- Also allow double-click
  vim.keymap.set('n', '<2-LeftMouse>', function()
    M._jump_to_file()
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

function M._jump_to_file()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1]

    local log_entry = log_data[line_num]
    if not log_entry then
	return
    end

    -- Check if file exists
    if vim.fn.filereadable(log_entry.file) == 0 then
	vim.notify('File not found: ' .. log_entry.file, vim.log.levels.ERROR)
	return
    end

    -- Find a suitable window to open the file in
    local target_win = M._find_suitable_window()

    if target_win then
	-- Switch to the target window
	vim.api.nvim_set_current_win(target_win)
    else
	-- Create a new window
	if config.get().window.position == 'right' or config.get().window.position == 'left' then
	    vim.cmd('wincmd p') -- Go to previous window
	    if vim.api.nvim_get_current_win() == win then
		-- If we're still in the log window, create a new split
	        vim.cmd('vertical split')
	    end
	else
	    vim.cmd('wincmd p') -- Go to previous window
	    if vim.api.nvim_get_current_win() == win then
		-- If we're still in the log window, create a new split
		vim.cmd('split')
	    end
	end
    end

    -- Open the file
    vim.cmd('edit ' .. vim.fn.fnameescape(log_entry.file))

    -- Jump to the line
    if not log_entry.is_header then
	vim.api.nvim_win_set_cursor(0, {log_entry.line, 0})
	-- Center the line in the window
	vim.cmd('normal! zz')
	-- Briefly highlight the line
	M._highlight_line(log_entry.line)
    end
end

function M._find_suitable_window()
   -- Find a window that's not the log window
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
      if win_id ~= win then
	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local buf_type = vim.api.nvim_buf_get_option(buf_id, 'buftype')
	-- Prefer normal file buffers
	if buf_type == '' then
	  return win_id
	end
      end
    end
    return nil 
end

function M._highlight_line(line_num)
    -- Create a temporary highlight for the target line
    local ns_id = vim.api.nvim_create_namespace('log_jump_highlight')
    vim.api.nvim_buf_add_highlight(0, ns_id, 'IncSearch', line_num - 1, 0, -1)

    -- Remove the highlight after a short delay
    vim.defer_fn(function()
	vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    end, 1000)
end

return M
