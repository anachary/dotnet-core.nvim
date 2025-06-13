-- dotnet-core/utils.lua - Utility functions for the plugin

local M = {}

-- Check if a command exists in the system
function M.command_exists(cmd)
  local handle = io.popen("where " .. cmd .. " 2>nul") -- Windows
  if not handle then
    handle = io.popen("which " .. cmd .. " 2>/dev/null") -- Unix-like
  end
  
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  
  return false
end

-- Execute a command and return the result
function M.execute_command(cmd, callback)
  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(output, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(output, data)
      end
    end,
    on_exit = function(_, exit_code)
      if callback then
        callback(exit_code, output)
      end
    end,
  })
  
  return job_id
end

-- Find files matching a pattern in a directory
function M.find_files(directory, pattern)
  local files = {}
  local cmd = string.format("find %s -name '%s' -type f 2>/dev/null", directory, pattern)
  
  -- Use Windows-compatible command if on Windows
  if vim.fn.has("win32") == 1 then
    cmd = string.format('dir /s /b "%s\\%s" 2>nul', directory, pattern)
  end
  
  local handle = io.popen(cmd)
  if handle then
    for line in handle:lines() do
      if line ~= "" then
        table.insert(files, line)
      end
    end
    handle:close()
  end
  
  return files
end

-- Get the root directory of a .NET solution or project
function M.get_dotnet_root(start_path)
  local path = start_path or vim.fn.expand("%:p:h")
  
  -- Look for solution file first
  local current = path
  while current ~= "/" and current ~= "" do
    local sln_files = vim.fn.glob(current .. "/*.sln", false, true)
    if #sln_files > 0 then
      return current, sln_files[1]
    end
    
    current = vim.fn.fnamemodify(current, ":h")
  end
  
  -- Look for project file
  current = path
  while current ~= "/" and current ~= "" do
    local proj_files = vim.fn.glob(current .. "/*.csproj", false, true)
    if #proj_files > 0 then
      return current, proj_files[1]
    end
    
    current = vim.fn.fnamemodify(current, ":h")
  end
  
  return nil, nil
end

-- Parse a .csproj file to extract project information
function M.parse_csproj(file_path)
  local project_info = {
    name = vim.fn.fnamemodify(file_path, ":t:r"),
    path = file_path,
    target_framework = nil,
    output_type = nil,
    references = {},
    package_references = {},
  }
  
  local file = io.open(file_path, "r")
  if not file then
    return project_info
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Extract target framework
  local target_framework = content:match("<TargetFramework>([^<]+)</TargetFramework>")
  if target_framework then
    project_info.target_framework = target_framework
  end
  
  -- Extract output type
  local output_type = content:match("<OutputType>([^<]+)</OutputType>")
  if output_type then
    project_info.output_type = output_type
  end
  
  -- Extract project references
  for ref in content:gmatch('<ProjectReference Include="([^"]+)"') do
    table.insert(project_info.references, ref)
  end
  
  -- Extract package references
  for pkg in content:gmatch('<PackageReference Include="([^"]+)"') do
    table.insert(project_info.package_references, pkg)
  end
  
  return project_info
end

-- Parse a .sln file to extract solution information
function M.parse_sln(file_path)
  local solution_info = {
    name = vim.fn.fnamemodify(file_path, ":t:r"),
    path = file_path,
    projects = {},
  }
  
  local file = io.open(file_path, "r")
  if not file then
    return solution_info
  end
  
  for line in file:lines() do
    -- Match project lines in solution file
    local project_match = line:match('Project%("{[^}]+}"%)[%s]*=[%s]*"([^"]+)"[%s]*,[%s]*"([^"]+)"')
    if project_match then
      local name, path = project_match:match('"([^"]+)"[%s]*,[%s]*"([^"]+)"')
      if name and path and path:match("%.csproj$") then
        table.insert(solution_info.projects, {
          name = name,
          path = vim.fn.fnamemodify(file_path, ":h") .. "/" .. path,
        })
      end
    end
  end
  
  file:close()
  return solution_info
end

-- Create a floating window with the given configuration
function M.create_floating_window(config)
  local default_config = {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    col = math.floor(vim.o.columns * 0.1),
    row = math.floor(vim.o.lines * 0.1),
    border = "rounded",
    style = "minimal",
  }
  
  local final_config = vim.tbl_extend("force", default_config, config or {})
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, true, final_config)
  
  return buf, win
end

-- Show a notification message
function M.notify(message, level)
  level = level or vim.log.levels.INFO
  vim.notify("[dotnet-core] " .. message, level)
end

-- Show an error message
function M.error(message)
  M.notify(message, vim.log.levels.ERROR)
end

-- Show a warning message
function M.warn(message)
  M.notify(message, vim.log.levels.WARN)
end

-- Show an info message
function M.info(message)
  M.notify(message, vim.log.levels.INFO)
end

-- Debounce function calls
function M.debounce(func, delay)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
    end
    timer = vim.defer_fn(function()
      func(unpack(args))
    end, delay)
  end
end

-- Check if current buffer is a .NET file
function M.is_dotnet_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return vim.tbl_contains({ "cs", "fs", "vb" }, filetype)
end

-- Get the current .NET project for the buffer
function M.get_current_project(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  
  if file_path == "" then
    return nil
  end
  
  local root, project_file = M.get_dotnet_root(vim.fn.fnamemodify(file_path, ":h"))
  if project_file then
    return M.parse_csproj(project_file)
  end
  
  return nil
end

return M
