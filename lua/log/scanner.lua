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
  
  local cmd = 'find ' .. vim.fn.shellescape(root) .. ' \( ' .. exclude_paths .. ' \) -o \( ' .. extensions .. ' \) -print'
  
  local output = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    for line in output:gmatch("[^\n]+") do
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
  
  -- Get file extension to determine comment style
  local file_ext = file_path:match('%.([^%.]+)$')
  if not file_ext then
    return logs
  end
  
  -- Read file
  local file = io.open(file_path, 'r')
  if not file then
    return logs
  end
  
  local line_num = 0
  for line in file:lines() do
    line_num = line_num + 1
    
    local comment_text = M._extract_comment(line, file_ext)
    if comment_text then
      M._check_patterns_in_comment(logs, cfg.patterns, file_path, line_num, line, comment_text)
    end
  end
  
  file:close()
  return logs
end

function M._get_file_comment_pattern(file_ext)
  local cfg = config.get()
  -- Normalize extension
  local ext = file_ext:lower()
  
  -- Handle common aliases
  local ext_map = {
    js = 'javascript',
    ts = 'typescript',
    py = 'python',
    rb = 'ruby',
    pl = 'perl',
    cc = 'cpp',
    cxx = 'cpp',
    hpp = 'cpp',
    h = 'c',
  }
  
  ext = ext_map[ext] or ext
  return cfg.comment_patterns[ext]
end

function M._extract_comment(line, file_ext)
  local pattern = M._get_file_comment_pattern(file_ext)
  if not pattern then
    return nil
  end
  
  local comment_start = line:find(pattern)
  if comment_start then
    -- Extract everything after the comment marker
    return line:sub(comment_start + #pattern)
  end
  
  return nil
end

function M._check_patterns_in_comment(logs, patterns, file_path, line_num, full_line, comment_text)
  -- Check each pattern within the comment text
  for _, pattern in ipairs(patterns) do
    local pattern_start = comment_text:find(pattern, 1, true)
    if pattern_start then
      local log_text = comment_text:sub(pattern_start):gsub('^%s+', ''):gsub('%s+$', '')
      
      table.insert(logs, {
        file = file_path,
        line = line_num,
        pattern = pattern:sub(1, -2), -- Remove the colon
        text = log_text,
        full_line = full_line:gsub('^%s+', ''):gsub('%s+$', ''),
      })
      break -- Only match first pattern per line
    end
  end
end

return M