if vim.g.loaded_log_plugin then
    return
end
vim.g.loaded_log_plugin = 1

-- Create user commands
vim.api.nvim_create_user_command("LogScan", function()
    require('log').scan_project()
end, { desc = 'Scan project for log comments' })

vim.api.nvim_create_user_command('LogShow', function()
  require('log').show_logs()
end, { desc = 'Show aggregated logs' })

vim.api.nvim_create_user_command('LogToggle', function()
  require('log').toggle()
end, { desc = 'Toggle log window' })

vim.api.nvim_create_user_command('LogExport', function(opts)
  local logs = require('log').export_logs()
  if opts.fargs and #opts.fargs > 0 then
    local shell_cmd = table.concat(opts.fargs, " ")
    local final_cmd = "echo " .. vim.fn.shellescape(logs) .. " | " .. shell_cmd
    local result = vim.fn.system(final_cmd)
    print(result)
  else
    print(logs)
  end
end, { desc = 'Export logs, optionally piping to a shell command', nargs = '*' })

-- TODO: Help me
