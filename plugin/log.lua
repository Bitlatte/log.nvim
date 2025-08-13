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

vim.api.nvim_create_user_command('LogExport', function()
  print(require('log').export_logs())
end, { desc = 'Export logs to a parseable format' })

