-- dotnet-core/project.lua - Project management and solution explorer

local M = {}
local utils = require('dotnet-core.utils')
local config = require('dotnet-core.config')

-- Project state
local current_solution = nil
local current_projects = {}
local explorer_buffer = nil
local explorer_window = nil
local explorer_tree = {} -- Tree structure for file navigation
local explorer_config = {} -- Cached configuration
local current_filter = "" -- Current search filter
local expanded_nodes = {} -- Track expanded/collapsed state

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

-- Show solution explorer with flexible layout
function M.solution_explorer()
  -- Get configuration
  explorer_config = config.get("solution_explorer", {})

  -- Toggle if already open
  if explorer_window and vim.api.nvim_win_is_valid(explorer_window) then
    M.close_explorer()
    return
  end

  -- Create explorer based on layout preference
  local layout = explorer_config.layout or "floating"

  if layout == "floating" then
    M.create_floating_explorer()
  elseif layout == "side" then
    M.create_side_explorer()
  elseif layout == "split" then
    M.create_split_explorer()
  else
    M.create_floating_explorer() -- fallback
  end

  -- Build file tree
  M.build_file_tree()

  -- Populate the explorer
  M.populate_explorer()

  -- Set up keymaps
  M.setup_explorer_keymaps()
end

-- Populate the solution explorer with content
function M.populate_explorer()
  if not explorer_buffer then
    return
  end

  local lines = {}
  local display_config = explorer_config.display or {}
  local ui_config = config.get_ui_config()
  local se_icons = explorer_config.icons or {}
  local icons = vim.tbl_extend("force", ui_config.icons or {}, se_icons)

  -- Apply filter if active
  if current_filter ~= "" then
    table.insert(lines, "🔍 Filter: " .. current_filter)
    table.insert(lines, "")
  end

  -- Add solution information
  if current_solution then
    table.insert(lines, (icons.solution or "📁") .. " " .. current_solution.name)
    if not display_config.compact_mode then
      table.insert(lines, "")
    end

    -- Add projects from solution
    for _, project in ipairs(current_solution.projects) do
      if M.matches_filter(project.name) then
        local startup_marker = (display_config.show_startup_marker and M.is_startup_project(project.path)) and " " .. (icons.startup_marker or "⭐") or ""
        table.insert(lines, "  " .. (icons.project or "📦") .. " " .. project.name .. startup_marker)

        -- Add project details if enabled
        if display_config.show_project_details then
          local proj_details = M.parse_project(project.path)
          if not display_config.compact_mode then
            table.insert(lines, "    Framework: " .. (proj_details.target_framework or "Unknown"))
            table.insert(lines, "    Type: " .. proj_details.output_type)
          end
        end

        -- Add file tree if enabled
        if display_config.show_file_tree then
          M.add_file_tree_to_lines(lines, project.path, "    ")
        end
      end
    end
  else
    table.insert(lines, (icons.folder or "📁") .. " Workspace")
    if not display_config.compact_mode then
      table.insert(lines, "")
    end
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
  local keymaps = explorer_config.keymaps or {}

  -- Close explorer
  local close_keys = keymaps.close or { "q", "<Esc>" }
  for _, key in ipairs(close_keys) do
    vim.keymap.set('n', key, function()
      M.close_explorer()
    end, opts)
  end
  
  -- Refresh explorer
  vim.keymap.set('n', keymaps.refresh or 'r', function()
    M.refresh_explorer()
  end, opts)

  -- Open item under cursor
  local open_keys = keymaps.open or { "<CR>", "o" }
  for _, key in ipairs(open_keys) do
    vim.keymap.set('n', key, function()
      M.open_item_under_cursor()
    end, opts)
  end

  -- Expand/collapse
  vim.keymap.set('n', keymaps.expand_collapse or '<Space>', function()
    M.toggle_expand_under_cursor()
  end, opts)

  -- Build project under cursor
  vim.keymap.set('n', keymaps.build_project or 'b', function()
    M.build_project_under_cursor()
  end, opts)

  -- Run project under cursor
  vim.keymap.set('n', keymaps.run_project or 'R', function()
    M.run_project_under_cursor()
  end, opts)

  -- Set project under cursor as startup project
  vim.keymap.set('n', keymaps.set_startup or 's', function()
    M.set_startup_project_under_cursor()
  end, opts)

  -- Show details
  vim.keymap.set('n', keymaps.show_details or 'i', function()
    M.show_item_details()
  end, opts)

  -- Toggle hidden files
  vim.keymap.set('n', keymaps.toggle_hidden or 'H', function()
    M.toggle_hidden_files()
  end, opts)

  -- Search/filter
  vim.keymap.set('n', keymaps.search or '/', function()
    M.start_search()
  end, opts)
end

-- Open item under cursor in the explorer
function M.open_item_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  -- Parse different types of items from the line
  local item_info = M.parse_explorer_line(line)

  if not item_info then
    return
  end

  -- Handle different item types
  if item_info.type == "project" then
    M.open_project_file(item_info)
  elseif item_info.type == "file" then
    M.open_file(item_info)
  elseif item_info.type == "directory" then
    M.toggle_directory(item_info)
  elseif item_info.type == "reference" then
    M.jump_to_reference(item_info)
  elseif item_info.type == "dependency" then
    M.show_dependency_info(item_info)
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
    project_name = trim(project_name)  -- Remove any trailing spaces
    local project = M.find_project_by_name(project_name)
    if project then
      require('dotnet-core.dotnet').set_startup_project(project.path)
      -- Refresh the explorer to show the new startup project marker
      M.populate_explorer()
    end
  end
end

-- === FLEXIBLE SOLUTION EXPLORER FUNCTIONS ===

-- Close explorer
function M.close_explorer()
  if explorer_window and vim.api.nvim_win_is_valid(explorer_window) then
    vim.api.nvim_win_close(explorer_window, true)
    explorer_window = nil
    explorer_buffer = nil
  end
end

-- Create floating window explorer
function M.create_floating_explorer()
  local size_config = explorer_config.size or {}
  local width = math.floor(vim.o.columns * (size_config.width or 0.3))
  local height = math.floor(vim.o.lines * (size_config.height or 0.8))

  -- Ensure minimum size
  width = math.max(width, size_config.min_width or 30)
  height = math.max(height, size_config.min_height or 10)

  explorer_buffer, explorer_window = utils.create_floating_window({
    title = "Solution Explorer",
    width = width,
    height = height,
    col = 0,
    row = math.floor((vim.o.lines - height) / 2),
    border = config.get("ui.border", "rounded"),
  })

  M.setup_buffer_options()
end

-- Create side panel explorer
function M.create_side_explorer()
  local size_config = explorer_config.size or {}
  local position = explorer_config.side_position or "left"
  local width = math.floor(vim.o.columns * (size_config.width or 0.3))
  width = math.max(width, size_config.min_width or 30)

  -- Create vertical split
  if position == "left" then
    vim.cmd("topleft " .. width .. "vnew")
  else
    vim.cmd("botright " .. width .. "vnew")
  end

  explorer_buffer = vim.api.nvim_get_current_buf()
  explorer_window = vim.api.nvim_get_current_win()

  M.setup_buffer_options()
end

-- Create split window explorer
function M.create_split_explorer()
  local size_config = explorer_config.size or {}
  local height = math.floor(vim.o.lines * (size_config.height or 0.3))
  height = math.max(height, size_config.min_height or 10)

  -- Create horizontal split
  vim.cmd("botright " .. height .. "new")

  explorer_buffer = vim.api.nvim_get_current_buf()
  explorer_window = vim.api.nvim_get_current_win()

  M.setup_buffer_options()
end

-- Setup buffer options
function M.setup_buffer_options()
  vim.api.nvim_buf_set_option(explorer_buffer, 'modifiable', false)
  vim.api.nvim_buf_set_option(explorer_buffer, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(explorer_buffer, 'filetype', 'dotnet-explorer')
  vim.api.nvim_buf_set_option(explorer_buffer, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(explorer_buffer, 'swapfile', false)
  vim.api.nvim_win_set_option(explorer_window, 'wrap', false)
  vim.api.nvim_win_set_option(explorer_window, 'number', false)
  vim.api.nvim_win_set_option(explorer_window, 'relativenumber', false)
  vim.api.nvim_win_set_option(explorer_window, 'signcolumn', 'no')
end

-- Build file tree structure
function M.build_file_tree()
  explorer_tree = {}
  local display_config = explorer_config.display or {}

  if not display_config.show_file_tree then
    return
  end

  -- Build tree for each project
  for _, project in ipairs(current_projects) do
    local project_dir = vim.fn.fnamemodify(project.path, ":h")
    local tree_node = {
      name = project.name,
      path = project.path,
      type = "project",
      children = {},
      expanded = expanded_nodes[project.path] or display_config.auto_expand_projects,
    }

    if tree_node.expanded then
      M.scan_directory(project_dir, tree_node, 0, display_config.max_depth or 3)
    end

    table.insert(explorer_tree, tree_node)
  end
end

-- Scan directory for file tree
function M.scan_directory(dir, parent_node, depth, max_depth)
  if depth >= max_depth then
    return
  end

  local display_config = explorer_config.display or {}
  local handle = vim.loop.fs_scandir(dir)

  if not handle then
    return
  end

  local entries = {}
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    -- Skip hidden files unless configured to show them
    if not display_config.show_hidden_files and name:match("^%.") then
      goto continue
    end

    -- Skip common build/temp directories
    if name == "bin" or name == "obj" or name == "node_modules" or name == ".git" then
      goto continue
    end

    local full_path = dir .. "/" .. name
    local node = {
      name = name,
      path = full_path,
      type = type,
      children = {},
      expanded = expanded_nodes[full_path] or false,
    }

    if type == "directory" and node.expanded then
      M.scan_directory(full_path, node, depth + 1, max_depth)
    end

    table.insert(entries, node)

    ::continue::
  end

  -- Sort entries: directories first, then files
  table.sort(entries, function(a, b)
    if a.type ~= b.type then
      return a.type == "directory"
    end
    return a.name < b.name
  end)

  parent_node.children = entries
end

-- Helper functions for flexible solution explorer

-- Check if item matches current filter
function M.matches_filter(name)
  if current_filter == "" then
    return true
  end
  return name:lower():find(current_filter:lower(), 1, true) ~= nil
end

-- Add file tree to display lines
function M.add_file_tree_to_lines(lines, project_path, indent)
  for _, node in ipairs(explorer_tree) do
    if node.path == project_path then
      M.add_tree_node_to_lines(lines, node, indent)
      break
    end
  end
end

-- Add tree node to display lines
function M.add_tree_node_to_lines(lines, node, indent)
  local icons = explorer_config.icons or {}

  for _, child in ipairs(node.children) do
    if M.matches_filter(child.name) then
      local icon = ""
      local expand_icon = ""

      if child.type == "directory" then
        expand_icon = child.expanded and (icons.expanded or "▼") or (icons.collapsed or "▶")
        icon = icons.folder or "📂"
      else
        -- File type specific icons
        if child.name:match("%.cs$") then
          icon = icons.cs_file or "🔷"
        elseif child.name:match("Test%.cs$") or child.name:match("Tests%.cs$") then
          icon = icons.test_file or "🧪"
        elseif child.name:match("%.config$") or child.name:match("%.json$") then
          icon = icons.config_file or "⚙️"
        else
          icon = icons.file or "📄"
        end
      end

      local line = indent .. expand_icon .. " " .. icon .. " " .. child.name
      table.insert(lines, line)

      if child.expanded and #child.children > 0 then
        M.add_tree_node_to_lines(lines, child, indent .. "  ")
      end
    end
  end
end

-- Refresh explorer
function M.refresh_explorer()
  M.scan_workspace()
  M.build_file_tree()
  M.populate_explorer()
end

-- Toggle expand/collapse under cursor
function M.toggle_expand_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local path = M.extract_path_from_line(line)

  if path then
    expanded_nodes[path] = not expanded_nodes[path]
    M.refresh_explorer()
  end
end

-- Show item details
function M.show_item_details()
  local line = vim.api.nvim_get_current_line()
  local project_name = line:match("📦 ([^⭐]+)")

  if project_name then
    project_name = trim(project_name)
    local project = M.find_project_by_name(project_name)
    if project then
      local details = M.parse_project(project.path)
      local info = {
        "Project Details:",
        "Name: " .. project.name,
        "Path: " .. project.path,
        "Framework: " .. (details.target_framework or "Unknown"),
        "Type: " .. details.output_type,
        "Startup: " .. (M.is_startup_project(project.path) and "Yes" or "No"),
      }
      vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
    end
  end
end

-- Toggle hidden files
function M.toggle_hidden_files()
  local display_config = explorer_config.display or {}
  display_config.show_hidden_files = not display_config.show_hidden_files
  M.refresh_explorer()
  vim.notify("Hidden files: " .. (display_config.show_hidden_files and "Shown" or "Hidden"))
end

-- Start search/filter
function M.start_search()
  vim.ui.input({ prompt = "Filter: " }, function(input)
    if input then
      current_filter = input
      M.refresh_explorer()
    end
  end)
end

-- Go to current file in explorer
function M.goto_current_file()
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file ~= "" then
    -- Find and expand path to current file
    -- This would require more complex tree traversal
    vim.notify("Go to file: " .. vim.fn.fnamemodify(current_file, ":t"))
  end
end

-- Extract path from display line
function M.extract_path_from_line(line)
  -- This is a simplified version - would need more sophisticated parsing
  local project_name = line:match("📦 ([^⭐]+)")
  if project_name then
    project_name = trim(project_name)
    local project = M.find_project_by_name(project_name)
    return project and project.path
  end
  return nil
end

-- === ENHANCED NAVIGATION AND SELECTION ===

-- Helper function for trimming strings (compatible with older Neovim versions)
local function trim(s)
  if vim.trim then
    return vim.trim(s)
  else
    return s:match("^%s*(.-)%s*$")
  end
end

-- Parse explorer line to determine item type and extract information
function M.parse_explorer_line(line)
  -- Remove leading whitespace and icons to get clean content
  local clean_line = line:gsub("^%s*", ""):gsub("^[▼▶]%s*", ""):gsub("^[📁📦📂📄🔷🧪⚙️]%s*", "")

  -- Project line: "📦 ProjectName ⭐"
  local project_name = line:match("📦%s*([^⭐]+)")
  if project_name then
    project_name = trim(project_name)
    local project = M.find_project_by_name(project_name)
    return {
      type = "project",
      name = project_name,
      path = project and project.path,
      project = project
    }
  end

  -- File line: "    📄 filename.cs" or "    🔷 Program.cs"
  local file_match = line:match("([📄🔷🧪⚙️]%s*.+%.%w+)$")
  if file_match then
    local file_name = file_match:gsub("^[📄🔷🧪⚙️]%s*", "")
    local file_path = nil

    -- Only try to resolve path if explorer is active
    if explorer_buffer and vim.api.nvim_buf_is_valid(explorer_buffer) then
      file_path = M.resolve_file_path(line, file_name)
    end

    return {
      type = "file",
      name = file_name,
      path = file_path,
      extension = file_name:match("%.(%w+)$")
    }
  end

  -- Directory line: "    📂 Controllers"
  local dir_match = line:match("📂%s*(.+)$")
  if dir_match then
    local dir_name = trim(dir_match)
    local dir_path = nil

    -- Only try to resolve path if explorer is active
    if explorer_buffer and vim.api.nvim_buf_is_valid(explorer_buffer) then
      dir_path = M.resolve_directory_path(line, dir_name)
    end

    return {
      type = "directory",
      name = dir_name,
      path = dir_path
    }
  end

  -- Reference line (for future use): "    → SomeClass.Method"
  local ref_match = line:match("→%s*(.+)$")
  if ref_match then
    return {
      type = "reference",
      name = trim(ref_match),
      target = trim(ref_match)
    }
  end

  return nil
end

-- Open project file
function M.open_project_file(item_info)
  if item_info.path and vim.fn.filereadable(item_info.path) == 1 then
    -- Store current window to return to
    local behavior_config = explorer_config.behavior or {}
    local return_window = vim.api.nvim_get_current_win()

    -- Switch to previous window or create new one
    local target_window = M.get_target_window()
    vim.api.nvim_set_current_win(target_window)

    -- Open the project file
    vim.cmd("edit " .. vim.fn.fnameescape(item_info.path))

    -- Close explorer if configured to do so
    if behavior_config.auto_close_on_select then
      M.close_explorer()
    end

    vim.notify("Opened project: " .. item_info.name)
  else
    vim.notify("Project file not found: " .. (item_info.path or "unknown"), vim.log.levels.ERROR)
  end
end

-- Open file
function M.open_file(item_info)
  if item_info.path and vim.fn.filereadable(item_info.path) == 1 then
    local behavior_config = explorer_config.behavior or {}

    -- Get target window for opening the file
    local target_window = M.get_target_window()
    vim.api.nvim_set_current_win(target_window)

    -- Open the file
    vim.cmd("edit " .. vim.fn.fnameescape(item_info.path))

    -- Close explorer if configured
    if behavior_config.auto_close_on_select then
      M.close_explorer()
    end

    vim.notify("Opened: " .. item_info.name)
  else
    vim.notify("File not found: " .. (item_info.path or "unknown"), vim.log.levels.ERROR)
  end
end

-- Toggle directory expansion
function M.toggle_directory(item_info)
  if item_info.path then
    expanded_nodes[item_info.path] = not expanded_nodes[item_info.path]
    M.refresh_explorer()

    local state = expanded_nodes[item_info.path] and "expanded" or "collapsed"
    vim.notify("Directory " .. state .. ": " .. item_info.name)
  end
end

-- Jump to reference (for future LSP integration)
function M.jump_to_reference(item_info)
  -- This would integrate with LSP to jump to the actual reference
  vim.notify("Jump to reference: " .. item_info.target .. " (LSP integration needed)")
end

-- Show dependency information
function M.show_dependency_info(item_info)
  vim.notify("Dependency info: " .. item_info.name .. " (to be implemented)")
end

-- Get target window for opening files
function M.get_target_window()
  -- Find a suitable window that's not the explorer
  local current_win = vim.api.nvim_get_current_win()
  local windows = vim.api.nvim_list_wins()

  for _, win in ipairs(windows) do
    if win ~= explorer_window then
      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')

      -- Prefer normal file buffers
      if buftype == '' then
        return win
      end
    end
  end

  -- If no suitable window found, create a new split
  if explorer_config.layout == "side" then
    -- For side layout, create vertical split
    vim.cmd("wincmd l") -- Move to right window
    if vim.api.nvim_get_current_win() == explorer_window then
      vim.cmd("vnew") -- Create new vertical split
    end
  else
    -- For floating/split layout, use current window or create new one
    vim.cmd("wincmd p") -- Go to previous window
    if vim.api.nvim_get_current_win() == explorer_window then
      vim.cmd("new") -- Create new split
    end
  end

  return vim.api.nvim_get_current_win()
end

-- Resolve file path based on explorer context
function M.resolve_file_path(line, file_name)
  -- Calculate indentation level to determine directory depth
  local indent_level = M.get_indent_level(line)

  -- Find the parent project by looking backwards in the explorer
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local project_path = nil

  -- Look backwards for project line
  for i = current_line, 1, -1 do
    local prev_line = vim.api.nvim_buf_get_lines(explorer_buffer, i-1, i, false)[1] or ""
    local proj_name = prev_line:match("📦%s*([^⭐]+)")
    if proj_name then
      local project = M.find_project_by_name(trim(proj_name))
      if project then
        project_path = vim.fn.fnamemodify(project.path, ":h")
        break
      end
    end
  end

  if not project_path then
    return nil
  end

  -- Build path by traversing directory structure
  local path_parts = { project_path }

  -- Look backwards to build directory path
  for i = current_line - 1, 1, -1 do
    local prev_line = vim.api.nvim_buf_get_lines(explorer_buffer, i-1, i, false)[1] or ""
    local prev_indent = M.get_indent_level(prev_line)

    if prev_indent < indent_level then
      local dir_name = prev_line:match("📂%s*(.+)$")
      if dir_name then
        table.insert(path_parts, 2, trim(dir_name))
        indent_level = prev_indent
      end
    end

    -- Stop when we reach project level
    if prev_line:match("📦") then
      break
    end
  end

  table.insert(path_parts, file_name)
  return table.concat(path_parts, "/")
end

-- Resolve directory path
function M.resolve_directory_path(line, dir_name)
  -- Similar logic to resolve_file_path but for directories
  local indent_level = M.get_indent_level(line)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  -- Find parent project
  for i = current_line, 1, -1 do
    local prev_line = vim.api.nvim_buf_get_lines(explorer_buffer, i-1, i, false)[1] or ""
    local proj_name = prev_line:match("📦%s*([^⭐]+)")
    if proj_name then
      local project = M.find_project_by_name(trim(proj_name))
      if project then
        local project_dir = vim.fn.fnamemodify(project.path, ":h")
        return project_dir .. "/" .. dir_name
      end
    end
  end

  return nil
end

-- Get indentation level of a line
function M.get_indent_level(line)
  local indent = line:match("^(%s*)")
  return #indent
end

-- File operations (enhanced implementations)
function M.new_file_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local item_info = M.parse_explorer_line(line)

  if item_info and (item_info.type == "project" or item_info.type == "directory") then
    vim.ui.input({ prompt = "New file name: " }, function(filename)
      if filename and filename ~= "" then
        local target_dir = item_info.type == "project"
          and vim.fn.fnamemodify(item_info.path, ":h")
          or item_info.path

        local new_file_path = target_dir .. "/" .. filename

        -- Create the file
        vim.cmd("edit " .. vim.fn.fnameescape(new_file_path))
        vim.cmd("write")

        -- Refresh explorer
        M.refresh_explorer()
        vim.notify("Created: " .. filename)
      end
    end)
  else
    vim.notify("Select a project or directory to create a new file")
  end
end

function M.delete_file_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local item_info = M.parse_explorer_line(line)

  if item_info and item_info.type == "file" and item_info.path then
    vim.ui.input({
      prompt = "Delete " .. item_info.name .. "? (y/N): "
    }, function(confirm)
      if confirm and confirm:lower() == "y" then
        local success = os.remove(item_info.path)
        if success then
          M.refresh_explorer()
          vim.notify("Deleted: " .. item_info.name)
        else
          vim.notify("Failed to delete: " .. item_info.name, vim.log.levels.ERROR)
        end
      end
    end)
  else
    vim.notify("Select a file to delete")
  end
end

function M.rename_file_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local item_info = M.parse_explorer_line(line)

  if item_info and item_info.type == "file" and item_info.path then
    vim.ui.input({
      prompt = "Rename to: ",
      default = item_info.name
    }, function(new_name)
      if new_name and new_name ~= "" and new_name ~= item_info.name then
        local dir = vim.fn.fnamemodify(item_info.path, ":h")
        local new_path = dir .. "/" .. new_name

        local success = os.rename(item_info.path, new_path)
        if success then
          M.refresh_explorer()
          vim.notify("Renamed: " .. item_info.name .. " → " .. new_name)
        else
          vim.notify("Failed to rename: " .. item_info.name, vim.log.levels.ERROR)
        end
      end
    end)
  else
    vim.notify("Select a file to rename")
  end
end

return M
