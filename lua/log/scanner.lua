local config = require('log.config')

local M = {}

-- Comment patterns for different file types
local comment_patterns = {
  -- Single-line comments
  lua = { '%-%-' },
  python = { '#' },
  javascript = { '//' },
  typescript = { '//' },
  go = { '//' },
  rust = { '//' },
  c = { '//' },
  cpp = { '//' },
  java = { '//' },
  php = { '//' },
  sh = { '#' },
  bash = { '#' },
  ruby = { '#' },
  perl = { '#' },
  vim = { '"' },
  
  -- Multi-line comments (we'll handle these separately)
  css = { '/\\*', '\\*/' },
  html = { '<!--', '-->' },
  xml = { '<!--', '-->' },
}

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
  local in_multiline_comment = false
  local multiline_start, multiline_end = M._get_multiline_patterns(file_ext)
  
  for line in file:lines() do
    line_num = line_num + 1
    
    -- Handle multi-line comments
    if multiline_start and multiline_end then
      if not in_multiline_comment then
        if line:find(multiline_start) then
          in_multiline_comment = true
        end
      end
      
      if in_multiline_comment then
        -- Check for patterns in multi-line comment
        local comment_text = M._extract_multiline_comment(line, multiline_start, multiline_end)
        if comment_text then
          M._check_patterns_in_comment(logs, cfg.patterns, file_path, line_num, line, comment_text)
        end
        
        if line:find(multiline_end) then
          in_multiline_comment = false
        end
      end
    end
    
    -- Handle single-line comments (even if we're in a multi-line comment context)
    if not in_multiline_comment then
      local comment_text = M._extract_single_line_comment(line, file_ext)
      if comment_text then
        M._check_patterns_in_comment(logs, cfg.patterns, file_path, line_num, line, comment_text)
      end
    end
  end
  
  file:close()
  return logs
end

function M._get_file_comment_patterns(file_ext)
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
  return comment_patterns[ext] or {}
end

function M._get_multiline_patterns(file_ext)
  local ext = file_ext:lower()
  if ext == 'css' or ext == 'c' or ext == 'cpp' or ext == 'java' or ext == 'javascript' or ext == 'typescript' then
    return '/\\*', '\\*/'
  elseif ext == 'html' or ext == 'xml' then
    return '<!%-%-', '%-%->'
  elseif ext == 'python' then
    -- Handle Python docstrings
    return '"""', '"""'
  end
  return nil, nil
end

function M._extract_single_line_comment(line, file_ext)
  local patterns = M._get_file_comment_patterns(file_ext)
  
  for _, pattern in ipairs(patterns) do
    local comment_start = line:find(pattern)
    if comment_start then
      -- Extract everything after the comment marker
      local comment_text = line:sub(comment_start):gsub('^' .. pattern .. '%s*', '')
      return comment_text
    end
  end
  
  return nil
end

function M._extract_multiline_comment(line, start_pattern, end_pattern)
  -- For multi-line comments, we want the content between markers
  local content = line
  
  -- Remove start marker if present
  content = content:gsub(start_pattern, '')
  -- Remove end marker if present  
  content = content:gsub(end_pattern, '')
  -- Remove common comment decorations
  content = content:gsub('^%s*%*%s*', '') -- Remove leading * in /* */ style
  content = content:gsub('^%s*', '') -- Remove leading whitespace
  
  return content ~= '' and content or nil
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
