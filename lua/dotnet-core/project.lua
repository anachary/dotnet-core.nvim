-- dotnet-core/project.lua - Project management and solution explorer

local M = {}
local utils = require('dotnet-core.utils')
local config = require('dotnet-core.config')

-- Project state
local current_solution = nil
local current_projects = {}
local explorer_buffer = nil
local explorer_window = nil

-- Setup project management
function M.setup()
  M.scan_workspace()
end

-- Scan workspace for .NET projects and solutions
function M.scan_workspace()
  local cwd = vim.fn.getcwd()
  
  -- Find solution files
  local sln_files = utils.find_files(cwd, "*.sln")
  if #sln_files > 0 then
    current_solution = M.parse_solution(sln_files[1])
    utils.info("Loaded solution: " .. current_solution.name)
  end
  
  -- Find all project files
  current_projects = {}
  local proj_files = utils.find_files(cwd, "*.csproj")
  for _, proj_file in ipairs(proj_files) do
    local project = M.parse_project(proj_file)
    table.insert(current_projects, project)
  end
  
  utils.info("Found " .. #current_projects .. " project(s)")
end

-- Parse a solution file
function M.parse_solution(sln_path)
  local solution = {
    name = vim.fn.fnamemodify(sln_path, ":t:r"),
    path = sln_path,
    projects = {},
    folders = {},
  }
  
  local file = io.open(sln_path, "r")
  if not file then
    return solution
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Parse project entries
  for line in content:gmatch("[^\r\n]+") do
    local project_match = line:match('Project%("{[^}]+}"%)[%s]*=[%s]*"([^"]+)"[%s]*,[%s]*"([^"]+)"[%s]*,[%s]*"([^"]+)"')
    if project_match then
      local guid, name, path = line:match('Project%("([^"]+)"%)[%s]*=[%s]*"([^"]+)"[%s]*,[%s]*"([^"]+)"')
      if name and path and path:match("%.csproj$") then
        table.insert(solution.projects, {
          name = name,
          path = vim.fn.fnamemodify(sln_path, ":h") .. "/" .. path,
          guid = guid,
        })
      elseif guid == "{2150E333-8FDC-42A3-9474-1A3956D46DE8}" then
        -- Solution folder
        table.insert(solution.folders, {
          name = name,
          guid = path, -- In solution folders, the third field is the folder GUID
        })
      end
    end
  end
  
  return solution
end

-- Parse a project file
function M.parse_project(proj_path)
  local project = {
    name = vim.fn.fnamemodify(proj_path, ":t:r"),
    path = proj_path,
    target_framework = nil,
    output_type = nil,
    references = {},
    package_references = {},
    source_files = {},
  }
  
  local file = io.open(proj_path, "r")
  if not file then
    return project
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Extract target framework
  project.target_framework = content:match("<TargetFramework>([^<]+)</TargetFramework>") or
                             content:match("<TargetFrameworks>([^<]+)</TargetFrameworks>")
  
  -- Extract output type
  project.output_type = content:match("<OutputType>([^<]+)</OutputType>") or "Library"
  
  -- Extract project references
  for ref in content:gmatch('<ProjectReference Include="([^"]+)"') do
    table.insert(project.references, {
      path = ref,
      name = vim.fn.fnamemodify(ref, ":t:r"),
    })
  end
  
  -- Extract package references
  for pkg_line in content:gmatch('<PackageReference[^>]*Include="([^"]+)"[^>]*>') do
    local name = pkg_line
    local version = content:match('<PackageReference[^>]*Include="' .. name .. '"[^>]*Version="([^"]+)"')
    table.insert(project.package_references, {
      name = name,
      version = version or "Unknown",
    })
  end
  
  -- Find source files
  local proj_dir = vim.fn.fnamemodify(proj_path, ":h")
  local cs_files = utils.find_files(proj_dir, "*.cs")
  for _, cs_file in ipairs(cs_files) do
    table.insert(project.source_files, {
      path = cs_file,
      name = vim.fn.fnamemodify(cs_file, ":t"),
      type = "cs",
    })
  end
  
  return project
end

-- Show solution explorer
function M.solution_explorer()
  if explorer_window and vim.api.nvim_win_is_valid(explorer_window) then
    vim.api.nvim_win_close(explorer_window, true)
    explorer_window = nil
    return
  end
  
  -- Create floating window for solution explorer
  local width = math.floor(vim.o.columns * 0.3)
  local height = math.floor(vim.o.lines * 0.8)
  
  explorer_buffer, explorer_window = utils.create_floating_window({
    title = "Solution Explorer",
    width = width,
    height = height,
    col = 0,
    row = math.floor((vim.o.lines - height) / 2),
    border = config.get("ui.border", "rounded"),
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(explorer_buffer, 'modifiable', false)
  vim.api.nvim_buf_set_option(explorer_buffer, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(explorer_buffer, 'filetype', 'dotnet-explorer')
  
  -- Populate the explorer
  M.populate_explorer()
  
  -- Set up keymaps for the explorer
  M.setup_explorer_keymaps()
end

-- Populate the solution explorer with content
function M.populate_explorer()
  if not explorer_buffer then
    return
  end
  
  local lines = {}
  local ui_config = config.get_ui_config()
  local icons = ui_config.icons or {}
  
  -- Add solution information
  if current_solution then
    table.insert(lines, (icons.solution or "📁") .. " " .. current_solution.name)
    table.insert(lines, "")
    
    -- Add projects from solution
    for _, project in ipairs(current_solution.projects) do
      local startup_marker = M.is_startup_project(project.path) and " ⭐" or ""
      table.insert(lines, "  " .. (icons.project or "📦") .. " " .. project.name .. startup_marker)
    end
  else
    table.insert(lines, "📁 Workspace")
    table.insert(lines, "")
  end
  
  -- Add standalone projects
  if #current_projects > 0 then
    if current_solution then
      table.insert(lines, "")
      table.insert(lines, "Other Projects:")
    end
    
    for _, project in ipairs(current_projects) do
      local is_in_solution = false
      if current_solution then
        for _, sln_proj in ipairs(current_solution.projects) do
          if sln_proj.path == project.path then
            is_in_solution = true
            break
          end
        end
      end
      
      if not is_in_solution then
        local startup_marker = M.is_startup_project(project.path) and " ⭐" or ""
        table.insert(lines, "  " .. (icons.project or "📦") .. " " .. project.name .. startup_marker)
        table.insert(lines, "    Target: " .. (project.target_framework or "Unknown"))
        table.insert(lines, "    Type: " .. project.output_type)
        
        if #project.package_references > 0 then
          table.insert(lines, "    📚 Packages (" .. #project.package_references .. ")")
        end
        
        if #project.references > 0 then
          table.insert(lines, "    🔗 References (" .. #project.references .. ")")
        end
        
        table.insert(lines, "")
      end
    end
  end
  
  if #lines == 0 then
    table.insert(lines, "No .NET projects found")
    table.insert(lines, "")
    table.insert(lines, "Create a new project with:")
    table.insert(lines, "  :DotnetCoreNewProject")
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_option(explorer_buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(explorer_buffer, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(explorer_buffer, 'modifiable', false)
end

-- Set up keymaps for the solution explorer
function M.setup_explorer_keymaps()
  if not explorer_buffer then
    return
  end
  
  local opts = { noremap = true, silent = true, buffer = explorer_buffer }
  
  -- Close explorer
  vim.keymap.set('n', 'q', function()
    if explorer_window then
      vim.api.nvim_win_close(explorer_window, true)
      explorer_window = nil
    end
  end, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    if explorer_window then
      vim.api.nvim_win_close(explorer_window, true)
      explorer_window = nil
    end
  end, opts)
  
  -- Refresh explorer
  vim.keymap.set('n', 'r', function()
    M.scan_workspace()
    M.populate_explorer()
  end, opts)
  
  -- Open project/file under cursor
  vim.keymap.set('n', '<CR>', function()
    M.open_item_under_cursor()
  end, opts)
  
  vim.keymap.set('n', 'o', function()
    M.open_item_under_cursor()
  end, opts)
  
  -- Build project under cursor
  vim.keymap.set('n', 'b', function()
    M.build_project_under_cursor()
  end, opts)
  
  -- Run project under cursor
  vim.keymap.set('n', 'R', function()
    M.run_project_under_cursor()
  end, opts)

  -- Set project under cursor as startup project
  vim.keymap.set('n', 's', function()
    M.set_startup_project_under_cursor()
  end, opts)
end

-- Open item under cursor in the explorer
function M.open_item_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local project_name = line:match("📦 (.+)") or line:match("📁 (.+)")
  
  if project_name then
    -- Find the project
    local project = M.find_project_by_name(project_name)
    if project then
      -- Open the project file
      vim.cmd("edit " .. project.path)
      if explorer_window then
        vim.api.nvim_win_close(explorer_window, true)
        explorer_window = nil
      end
    end
  end
end

-- Build project under cursor
function M.build_project_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local project_name = line:match("📦 (.+)")
  
  if project_name then
    local project = M.find_project_by_name(project_name)
    if project then
      require('dotnet-core.dotnet').build_specific_project(project.path)
    end
  end
end

-- Run project under cursor
function M.run_project_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local project_name = line:match("📦 (.+)")
  
  if project_name then
    local project = M.find_project_by_name(project_name)
    if project and project.output_type == "Exe" then
      require('dotnet-core.dotnet').run_specific_project(project.path)
    else
      utils.warn("Project is not executable")
    end
  end
end

-- Find project by name
function M.find_project_by_name(name)
  for _, project in ipairs(current_projects) do
    if project.name == name then
      return project
    end
  end
  
  if current_solution then
    for _, project in ipairs(current_solution.projects) do
      if project.name == name then
        return M.parse_project(project.path)
      end
    end
  end
  
  return nil
end

-- Show project structure in a more detailed view
function M.show_structure()
  local lines = {}
  
  if current_solution then
    table.insert(lines, "Solution: " .. current_solution.name)
    table.insert(lines, "Path: " .. current_solution.path)
    table.insert(lines, "")
    
    for _, project in ipairs(current_solution.projects) do
      table.insert(lines, "Project: " .. project.name)
      table.insert(lines, "  Path: " .. project.path)
      
      local proj_details = M.parse_project(project.path)
      table.insert(lines, "  Framework: " .. (proj_details.target_framework or "Unknown"))
      table.insert(lines, "  Type: " .. proj_details.output_type)
      table.insert(lines, "")
    end
  end
  
  for _, project in ipairs(current_projects) do
    table.insert(lines, "Project: " .. project.name)
    table.insert(lines, "  Path: " .. project.path)
    table.insert(lines, "  Framework: " .. (project.target_framework or "Unknown"))
    table.insert(lines, "  Type: " .. project.output_type)
    
    if #project.package_references > 0 then
      table.insert(lines, "  Package References:")
      for _, pkg in ipairs(project.package_references) do
        table.insert(lines, "    " .. pkg.name .. " (" .. pkg.version .. ")")
      end
    end
    
    if #project.references > 0 then
      table.insert(lines, "  Project References:")
      for _, ref in ipairs(project.references) do
        table.insert(lines, "    " .. ref.name)
      end
    end
    
    table.insert(lines, "")
  end
  
  -- Show in a floating window
  local buf, win = utils.create_floating_window({
    title = "Project Structure",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
  })
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'dotnet-structure')
  
  -- Close on q or Esc
  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(win, true) end, opts)
end

-- Get current project information
function M.get_current_project()
  return current_projects[1] -- Return first project for now
end

-- Get current solution information
function M.get_current_solution()
  return current_solution
end

-- Check if a project is the startup project
function M.is_startup_project(project_path)
  local dotnet = require('dotnet-core.dotnet')
  local startup = dotnet.get_startup_project()
  return startup and startup == project_path
end

-- Add keymap to set startup project in solution explorer
function M.setup_startup_project_keymaps()
  if not explorer_buffer then
    return
  end

  local opts = { noremap = true, silent = true, buffer = explorer_buffer }

  -- Set project under cursor as startup project
  vim.keymap.set('n', 's', function()
    M.set_startup_project_under_cursor()
  end, opts)
end

-- Set project under cursor as startup project
function M.set_startup_project_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local project_name = line:match("📦 ([^⭐]+)")  -- Extract name without startup marker

  if project_name then
    project_name = vim.trim(project_name)  -- Remove any trailing spaces
    local project = M.find_project_by_name(project_name)
    if project then
      require('dotnet-core.dotnet').set_startup_project(project.path)
      -- Refresh the explorer to show the new startup project marker
      M.populate_explorer()
    end
  end
end

return M
