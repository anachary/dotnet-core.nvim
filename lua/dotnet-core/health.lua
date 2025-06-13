-- dotnet-core/health.lua - Health check functionality for the plugin

local M = {}
local utils = require('dotnet-core.utils')

-- Perform comprehensive health check
function M.check()
  local health = vim.health or require('health')
  
  health.report_start("dotnet-core.nvim Health Check")
  
  -- Check Neovim version
  M.check_neovim_version(health)
  
  -- Check .NET Core SDK
  M.check_dotnet_sdk(health)
  
  -- Check OmniSharp
  M.check_omnisharp(health)
  
  -- Check LSP configuration
  M.check_lsp_config(health)
  
  -- Check optional dependencies
  M.check_optional_dependencies(health)
  
  -- Check current project
  M.check_current_project(health)
  
  -- Check plugin configuration
  M.check_plugin_config(health)
end

-- Check Neovim version compatibility
function M.check_neovim_version(health)
  health.report_start("Neovim Version")
  
  if vim.fn.has('nvim-0.8.0') == 1 then
    health.report_ok("Neovim version is compatible (>= 0.8.0)")
  else
    health.report_error("Neovim version is too old. Requires >= 0.8.0", {
      "Please update Neovim to version 0.8.0 or later",
      "Visit: https://github.com/neovim/neovim/releases"
    })
  end
end

-- Check .NET Core SDK installation
function M.check_dotnet_sdk(health)
  health.report_start(".NET Core SDK")
  
  if utils.command_exists("dotnet") then
    -- Get dotnet version
    local handle = io.popen("dotnet --version 2>&1")
    if handle then
      local version = handle:read("*a"):gsub("%s+", "")
      handle:close()
      
      if version and version ~= "" then
        health.report_ok("dotnet CLI found (version: " .. version .. ")")
        
        -- Check for .NET Core runtime
        M.check_dotnet_runtimes(health)
      else
        health.report_warn("dotnet CLI found but version could not be determined")
      end
    else
      health.report_error("Could not execute dotnet command")
    end
  else
    health.report_error("dotnet CLI not found", {
      "Please install .NET Core SDK",
      "Visit: https://dotnet.microsoft.com/download"
    })
  end
end

-- Check installed .NET runtimes
function M.check_dotnet_runtimes(health)
  local handle = io.popen("dotnet --list-runtimes 2>&1")
  if handle then
    local runtimes = handle:read("*a")
    handle:close()
    
    if runtimes and runtimes ~= "" then
      local runtime_lines = vim.split(runtimes, "\n")
      local core_runtimes = {}
      
      for _, line in ipairs(runtime_lines) do
        if line:match("Microsoft%.NETCore%.App") then
          table.insert(core_runtimes, line)
        end
      end
      
      if #core_runtimes > 0 then
        health.report_ok("Found " .. #core_runtimes .. " .NET Core runtime(s)")
      else
        health.report_warn("No .NET Core runtimes found")
      end
    end
  end
end

-- Check OmniSharp installation
function M.check_omnisharp(health)
  health.report_start("OmniSharp Language Server")
  
  if utils.command_exists("omnisharp") then
    health.report_ok("OmniSharp found in PATH")
  else
    health.report_warn("OmniSharp not found in PATH", {
      "Install OmniSharp for better C# language support",
      "Visit: https://github.com/OmniSharp/omnisharp-roslyn",
      "Or use Mason: :MasonInstall omnisharp"
    })
  end
end

-- Check LSP configuration
function M.check_lsp_config(health)
  health.report_start("LSP Configuration")
  
  local has_lspconfig, lspconfig = pcall(require, 'lspconfig')
  if has_lspconfig then
    health.report_ok("nvim-lspconfig is available")
    
    -- Check if OmniSharp is configured
    if lspconfig.omnisharp then
      health.report_ok("OmniSharp LSP configuration is available")
    else
      health.report_warn("OmniSharp LSP configuration not found")
    end
  else
    health.report_error("nvim-lspconfig not found", {
      "Please install nvim-lspconfig",
      "Visit: https://github.com/neovim/nvim-lspconfig"
    })
  end
end

-- Check optional dependencies
function M.check_optional_dependencies(health)
  health.report_start("Optional Dependencies")
  
  -- Check Telescope
  local has_telescope, _ = pcall(require, 'telescope')
  if has_telescope then
    health.report_ok("Telescope.nvim is available (enhanced UI)")
  else
    health.report_info("Telescope.nvim not found (optional - provides enhanced UI)")
  end
  
  -- Check nvim-dap
  local has_dap, _ = pcall(require, 'dap')
  if has_dap then
    health.report_ok("nvim-dap is available (debugging support)")
  else
    health.report_info("nvim-dap not found (optional - provides debugging support)")
  end
  
  -- Check nvim-treesitter
  local has_treesitter, _ = pcall(require, 'nvim-treesitter')
  if has_treesitter then
    health.report_ok("nvim-treesitter is available (enhanced syntax highlighting)")
  else
    health.report_info("nvim-treesitter not found (optional - provides enhanced syntax highlighting)")
  end
  
  -- Check Mason
  local has_mason, _ = pcall(require, 'mason')
  if has_mason then
    health.report_ok("Mason.nvim is available (package management)")
  else
    health.report_info("Mason.nvim not found (optional - provides package management)")
  end
end

-- Check current project setup
function M.check_current_project(health)
  health.report_start("Current Project")
  
  local cwd = vim.fn.getcwd()
  
  -- Check for solution files
  local sln_files = utils.find_files(cwd, "*.sln")
  if #sln_files > 0 then
    health.report_ok("Found " .. #sln_files .. " solution file(s)")
    for _, sln in ipairs(sln_files) do
      health.report_info("  " .. vim.fn.fnamemodify(sln, ":t"))
    end
  else
    health.report_info("No solution files found in current directory")
  end
  
  -- Check for project files
  local proj_files = utils.find_files(cwd, "*.csproj")
  if #proj_files > 0 then
    health.report_ok("Found " .. #proj_files .. " C# project file(s)")
    for _, proj in ipairs(proj_files) do
      health.report_info("  " .. vim.fn.fnamemodify(proj, ":t"))
    end
  else
    health.report_info("No C# project files found in current directory")
  end
  
  -- Check for F# projects
  local fsproj_files = utils.find_files(cwd, "*.fsproj")
  if #fsproj_files > 0 then
    health.report_ok("Found " .. #fsproj_files .. " F# project file(s)")
  end
  
  -- Check for VB.NET projects
  local vbproj_files = utils.find_files(cwd, "*.vbproj")
  if #vbproj_files > 0 then
    health.report_ok("Found " .. #vbproj_files .. " VB.NET project file(s)")
  end
  
  if #sln_files == 0 and #proj_files == 0 and #fsproj_files == 0 and #vbproj_files == 0 then
    health.report_warn("No .NET projects found in current directory", {
      "Navigate to a .NET project directory",
      "Or create a new project with: :DotnetCoreNewProject"
    })
  end
end

-- Check plugin configuration
function M.check_plugin_config(health)
  health.report_start("Plugin Configuration")
  
  local config = require('dotnet-core.config')
  local is_valid, errors = config.validate()
  
  if is_valid then
    health.report_ok("Plugin configuration is valid")
  else
    health.report_error("Plugin configuration has errors:")
    for _, error in ipairs(errors) do
      health.report_error("  " .. error)
    end
  end
  
  -- Check specific configuration sections
  local lsp_config = config.get_lsp_config()
  if lsp_config and lsp_config.cmd then
    health.report_ok("LSP configuration is set")
  else
    health.report_warn("LSP configuration may be incomplete")
  end
  
  local dotnet_config = config.get_dotnet_config()
  if dotnet_config then
    health.report_ok("Dotnet configuration is set")
    
    if dotnet_config.auto_restore then
      health.report_info("Auto-restore is enabled")
    end
    
    if dotnet_config.build_on_save then
      health.report_info("Build-on-save is enabled")
    end
  end
end

-- Quick health check (minimal version)
function M.quick_check()
  local issues = {}
  
  -- Check essential requirements
  if vim.fn.has('nvim-0.8.0') ~= 1 then
    table.insert(issues, "Neovim version too old (requires >= 0.8.0)")
  end
  
  if not utils.command_exists("dotnet") then
    table.insert(issues, ".NET Core SDK not found")
  end
  
  local has_lspconfig, _ = pcall(require, 'lspconfig')
  if not has_lspconfig then
    table.insert(issues, "nvim-lspconfig not installed")
  end
  
  return #issues == 0, issues
end

-- Get health status as a table (for programmatic use)
function M.get_status()
  local status = {
    neovim_compatible = vim.fn.has('nvim-0.8.0') == 1,
    dotnet_available = utils.command_exists("dotnet"),
    omnisharp_available = utils.command_exists("omnisharp"),
    lspconfig_available = pcall(require, 'lspconfig'),
    telescope_available = pcall(require, 'telescope'),
    dap_available = pcall(require, 'dap'),
    current_project = {},
  }
  
  -- Get current project info
  local cwd = vim.fn.getcwd()
  status.current_project.solution_files = utils.find_files(cwd, "*.sln")
  status.current_project.csharp_projects = utils.find_files(cwd, "*.csproj")
  status.current_project.fsharp_projects = utils.find_files(cwd, "*.fsproj")
  status.current_project.vb_projects = utils.find_files(cwd, "*.vbproj")
  
  return status
end

return M
