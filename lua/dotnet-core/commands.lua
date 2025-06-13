-- dotnet-core/commands.lua - Command definitions for the plugin

local M = {}
local utils = require('dotnet-core.utils')

-- Setup all plugin commands
function M.setup()
  -- Create user commands for the plugin
  M.create_commands()
  
  utils.info("Commands registered successfully")
end

-- Create all user commands
function M.create_commands()
  -- Main plugin commands
  vim.api.nvim_create_user_command('DotnetCoreSetup', function()
    require('dotnet-core').setup()
  end, { desc = 'Setup dotnet-core plugin' })
  
  vim.api.nvim_create_user_command('DotnetCoreHealth', function()
    require('dotnet-core.health').check()
  end, { desc = 'Check plugin health' })
  
  -- Build and run commands
  vim.api.nvim_create_user_command('DotnetCoreBuild', function(opts)
    local config = opts.args ~= "" and opts.args or nil
    require('dotnet-core.dotnet').build(config)
  end, { 
    desc = 'Build the current .NET project/solution',
    nargs = '?',
    complete = function() return { 'Debug', 'Release' } end
  })
  
  vim.api.nvim_create_user_command('DotnetCoreRun', function(opts)
    local config = opts.args ~= "" and opts.args or nil
    require('dotnet-core.dotnet').run(config)
  end, { 
    desc = 'Run the current .NET project',
    nargs = '?',
    complete = function() return { 'Debug', 'Release' } end
  })
  
  vim.api.nvim_create_user_command('DotnetCoreTest', function(opts)
    local config = opts.args ~= "" and opts.args or nil
    require('dotnet-core.dotnet').test(config)
  end, { 
    desc = 'Run tests for the current .NET project/solution',
    nargs = '?',
    complete = function() return { 'Debug', 'Release' } end
  })
  
  vim.api.nvim_create_user_command('DotnetCoreRestore', function()
    require('dotnet-core.dotnet').restore()
  end, { desc = 'Restore NuGet packages' })
  
  vim.api.nvim_create_user_command('DotnetCoreClean', function(opts)
    local config = opts.args ~= "" and opts.args or nil
    require('dotnet-core.dotnet').clean(config)
  end, { 
    desc = 'Clean the current .NET project/solution',
    nargs = '?',
    complete = function() return { 'Debug', 'Release' } end
  })
  
  -- LSP and navigation commands
  vim.api.nvim_create_user_command('DotnetCoreFindReferences', function()
    require('dotnet-core.lsp').find_references()
  end, { desc = 'Find all references to symbol under cursor' })
  
  vim.api.nvim_create_user_command('DotnetCoreGoToImplementation', function()
    require('dotnet-core.lsp').go_to_implementation()
  end, { desc = 'Go to implementation of interface/abstract method' })
  
  vim.api.nvim_create_user_command('DotnetCoreRename', function()
    require('dotnet-core.lsp').rename()
  end, { desc = 'Rename symbol under cursor' })
  
  vim.api.nvim_create_user_command('DotnetCoreCodeAction', function()
    require('dotnet-core.lsp').code_action()
  end, { desc = 'Show available code actions' })
  
  -- Project management commands
  vim.api.nvim_create_user_command('DotnetCoreSolutionExplorer', function()
    require('dotnet-core.project').solution_explorer()
  end, { desc = 'Open solution explorer' })
  
  vim.api.nvim_create_user_command('DotnetCoreProjectStructure', function()
    require('dotnet-core.project').show_structure()
  end, { desc = 'Show project structure' })
  
  -- New project commands
  vim.api.nvim_create_user_command('DotnetCoreNewProject', function(opts)
    M.new_project(opts.args)
  end, { 
    desc = 'Create a new .NET project',
    nargs = '?',
    complete = M.get_project_templates
  })
  
  vim.api.nvim_create_user_command('DotnetCoreNewSolution', function(opts)
    M.new_solution(opts.args)
  end, { 
    desc = 'Create a new .NET solution',
    nargs = '?'
  })
  
  -- Package management commands
  vim.api.nvim_create_user_command('DotnetCoreAddPackage', function(opts)
    M.add_package(opts.args)
  end, { 
    desc = 'Add a NuGet package to the project',
    nargs = 1
  })
  
  vim.api.nvim_create_user_command('DotnetCoreRemovePackage', function(opts)
    M.remove_package(opts.args)
  end, { 
    desc = 'Remove a NuGet package from the project',
    nargs = 1
  })
  
  -- Debug commands
  vim.api.nvim_create_user_command('DotnetCoreDebugStart', function()
    require('dotnet-core.debug').start()
  end, { desc = 'Start debugging the current project' })

  vim.api.nvim_create_user_command('DotnetCoreDebugStop', function()
    require('dotnet-core.debug').stop()
  end, { desc = 'Stop debugging' })

  vim.api.nvim_create_user_command('DotnetCoreDebugToggleBreakpoint', function()
    require('dotnet-core.debug').toggle_breakpoint()
  end, { desc = 'Toggle breakpoint at current line' })

  -- Startup project commands
  vim.api.nvim_create_user_command('DotnetCoreSelectStartupProject', function()
    require('dotnet-core.dotnet').select_startup_project()
  end, { desc = 'Select which project to run as startup project' })

  vim.api.nvim_create_user_command('DotnetCoreSetStartupProject', function(opts)
    if opts.args == "" then
      require('dotnet-core.dotnet').select_startup_project()
    else
      require('dotnet-core.dotnet').set_startup_project(opts.args)
    end
  end, {
    desc = 'Set startup project by path or show selection UI',
    nargs = '?',
    complete = function()
      local dotnet = require('dotnet-core.dotnet')
      local projects = dotnet.get_executable_projects()
      local paths = {}
      for _, project in ipairs(projects) do
        table.insert(paths, project.path)
      end
      return paths
    end
  })
end

-- Create a new .NET project
function M.new_project(template)
  template = template or "console"
  
  vim.ui.input({ prompt = "Project name: " }, function(name)
    if not name or name == "" then
      utils.warn("Project name is required")
      return
    end
    
    local cmd = { "dotnet", "new", template, "-n", name }
    
    utils.info("Creating new " .. template .. " project: " .. name)
    
    utils.execute_command(cmd, function(exit_code, output)
      if exit_code == 0 then
        utils.info("Project created successfully")
        -- Change to the new project directory
        vim.cmd("cd " .. name)
        require('dotnet-core.dotnet').detect_project()
      else
        utils.error("Failed to create project")
        for _, line in ipairs(output) do
          if line ~= "" then
            print(line)
          end
        end
      end
    end)
  end)
end

-- Create a new .NET solution
function M.new_solution(name)
  vim.ui.input({ prompt = "Solution name: ", default = name }, function(solution_name)
    if not solution_name or solution_name == "" then
      utils.warn("Solution name is required")
      return
    end
    
    local cmd = { "dotnet", "new", "sln", "-n", solution_name }
    
    utils.info("Creating new solution: " .. solution_name)
    
    utils.execute_command(cmd, function(exit_code, output)
      if exit_code == 0 then
        utils.info("Solution created successfully")
        require('dotnet-core.dotnet').detect_project()
      else
        utils.error("Failed to create solution")
        for _, line in ipairs(output) do
          if line ~= "" then
            print(line)
          end
        end
      end
    end)
  end)
end

-- Add a NuGet package to the current project
function M.add_package(package_name)
  if not package_name or package_name == "" then
    vim.ui.input({ prompt = "Package name: " }, function(name)
      if name and name ~= "" then
        M.add_package(name)
      end
    end)
    return
  end
  
  local dotnet = require('dotnet-core.dotnet')
  local project_info = dotnet.get_project_info()
  
  if not project_info.has_project then
    utils.error("No .NET project found")
    return
  end
  
  local cmd = { "dotnet", "add", project_info.project, "package", package_name }
  
  utils.info("Adding package: " .. package_name)
  
  utils.execute_command(cmd, function(exit_code, output)
    if exit_code == 0 then
      utils.info("Package added successfully")
    else
      utils.error("Failed to add package")
      for _, line in ipairs(output) do
        if line ~= "" then
          print(line)
        end
      end
    end
  end)
end

-- Remove a NuGet package from the current project
function M.remove_package(package_name)
  if not package_name or package_name == "" then
    utils.warn("Package name is required")
    return
  end
  
  local dotnet = require('dotnet-core.dotnet')
  local project_info = dotnet.get_project_info()
  
  if not project_info.has_project then
    utils.error("No .NET project found")
    return
  end
  
  local cmd = { "dotnet", "remove", project_info.project, "package", package_name }
  
  utils.info("Removing package: " .. package_name)
  
  utils.execute_command(cmd, function(exit_code, output)
    if exit_code == 0 then
      utils.info("Package removed successfully")
    else
      utils.error("Failed to remove package")
      for _, line in ipairs(output) do
        if line ~= "" then
          print(line)
        end
      end
    end
  end)
end

-- Get available project templates for completion
function M.get_project_templates()
  return {
    "console",
    "classlib",
    "web",
    "webapi",
    "mvc",
    "blazorserver",
    "blazorwasm",
    "worker",
    "winforms",
    "wpf",
    "xunit",
    "nunit",
    "mstest"
  }
end

return M
