local config = require('log.config')
local scanner = require('log.scanner')
local ui = require('log.ui')

local M = {}

-- Internal state
M._logs = {}
M._is_open = false
M._current_filter = nil

function M.setup(opts)
  config.setup(opts)
  
  -- Create highlight group
  vim.api.nvim_set_hl(0, 'LogPattern', { link = 'Todo' })
  
  -- Auto-scan on plugin load
  M.scan_project()
  
  -- Set up autocommands for auto-refresh
  local group = vim.api.nvim_create_augroup('LogPlugin', { clear = true })
  vim.api.nvim_create_autocmd({'BufWritePost'}, {
    group = group,
    callback = function()
      if config.get().auto_refresh then
        M.scan_project()
        if M._is_open then
          ui.refresh(M._logs)
        end
      end
    end,
  })
end

function M.scan_project()
  M._logs = scanner.scan_project()
  M.highlight_logs()
  if M._is_open then
    ui.refresh(M.get_filtered_logs())
  end
  return M._logs
end

function M.highlight_logs()
  local ns_id = vim.api.nvim_create_namespace('log_pattern_highlight')
  
  -- Clear previous highlights
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  end
  
  -- Add new highlights
  for _, log in ipairs(M._logs) do
    local buf_id = vim.fn.bufnr(log.file)
    if buf_id ~= -1 then
      vim.api.nvim_buf_add_highlight(buf_id, ns_id, 'LogPattern', log.line - 1, 0, -1)
    end
  end
end

function M.show_logs()
  if not M._is_open then
    ui.open(M.get_filtered_logs())
    M._is_open = true
  else
    ui.focus()
  end
end

function M.hide_logs()
  if M._is_open then
    ui.close()
    M._is_open = false
  end
end

function M.toggle()
  if M._is_open then
    M.hide_logs()
  else
    M.show_logs()
  end
end

function M.get_logs()
  return M._logs
end

function M.get_filtered_logs()
  if not M._current_filter or M._current_filter == '' then
    return M._logs
  end


  local filtered_logs = {}
  local filter_pattern = M._current_filter:lower()

  for _, log in ipairs(M._logs) do
    local log_text = (log.pattern .. ': ' .. log.text):lower()
    if log_text:find(filter_pattern, 1, true) then
      table.insert(filtered_logs, log)
    end
  end

  return filtered_logs
end

function M.set_filter(pattern)
  M._current_filter = pattern
  if M._is_open then
    ui.refresh(M.get_filtered_logs())
  end
end

return M
