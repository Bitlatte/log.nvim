local config = require('log.config')
local scanner = require('log.scanner')
local ui = require('log.ui')

local M = {}

-- Internal state
M._logs = {}
M._is_open = false

function M.setup(opts)
  config.setup(opts)
  
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
  return M._logs
end

function M.show_logs()
  if not M._is_open then
    ui.open(M._logs)
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

return M
