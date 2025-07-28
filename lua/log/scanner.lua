local config = require('log.config')

local M = {}

function M.scan_project()
  local logs = {}
  local root = vim.fn.getcwd()
  
  -- Get all files to scan
  local files = M._get_files_to_scan(root)
  
  for _, file_path in ipairs(files) do
    local file_logs = M._scan_file(file_path)
    vim.list_extend(logs, file_logs)
  end
  
  -- Sort by file path, then by line number
  table.sort(logs, function(a, b)
    if a.file == b.file then
      return a.line < b.line
    end
    return a.file < b.file
  end)
  
  return logs
end

function M._get_files_to_scan(root)
  local files = {}
  local cfg = config.get()
  
  -- Build find command
  local extensions = table.concat(
    vim.tbl_map(function(ext) return '-name "*.' .. ext .. '"' end, cfg.file_extensions),
    ' -o '
  )
  
  local exclude_paths = table.concat(
    vim.tbl_map(function(dir) return '-path "*/' .. dir .. '" -prune' end, cfg.exclude_dirs),
    ' -o '
  )
  
  local cmd = string.format(
    'find %s \\( %s \\) -o \\( %s \\) -print',
    vim.fn.shellescape(root),
    exclude_paths,
    extensions
  )
  
  local output = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    for line in output:gmatch('[^\r\n]+') do
      if line ~= '' then
        table.insert(files, line)
      end
    end
  end
  
  return files
end

function M._scan_file(file_path)
  local logs = {}
  local cfg = config.get()
  
  -- Read file
  local file = io.open(file_path, 'r')
  if not file then
    return logs
  end
  
  local line_num = 0
  for line in file:lines() do
    line_num = line_num + 1
    
    -- Check each pattern
    for _, pattern in ipairs(cfg.patterns) do
      local comment_start = line:find(pattern, 1, true)
      if comment_start then
        local comment_text = line:sub(comment_start):gsub('^%s+', ''):gsub('%s+$', '')
        
        table.insert(logs, {
          file = file_path,
          line = line_num,
          pattern = pattern:sub(1, -2), -- Remove the colon
          text = comment_text,
          full_line = line:gsub('^%s+', ''):gsub('%s+$', ''),
        })
        break
      end
    end
  end
  
  file:close()
  return logs
end

return M
