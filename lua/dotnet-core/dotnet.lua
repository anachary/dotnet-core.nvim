-- dotnet-core/dotnet.lua - Dotnet CLI integration

local M = {}
local utils = require('dotnet-core.utils')
local config = require('dotnet-core.config')

-- Dotnet CLI state
local current_project = nil
local current_solution = nil
local build_output_buffer = nil

-- Setup dotnet CLI integration
function M.setup(dotnet_config)
  -- Check if dotnet CLI is available
  if not utils.command_exists("dotnet") then
    utils.error("dotnet CLI not found. Please install .NET Core SDK.")
    return false
  end
  
  -- Detect current project/solution
  M.detect_project()
  
  utils.info("Dotnet CLI integration initialized")
  return true
end

-- Detect current .NET project or solution
function M.detect_project()
  local cwd = vim.fn.getcwd()
  
  -- Look for solution files first
  local sln_files = utils.find_files(cwd, "*.sln")
  if #sln_files > 0 then
    current_solution = sln_files[1]
    utils.info("Detected solution: " .. vim.fn.fnamemodify(current_solution, ":t"))
  end
  
  -- Look for project files
  local proj_files = utils.find_files(cwd, "*.csproj")
  if #proj_files > 0 then
    current_project = proj_files[1]
    utils.info("Detected project: " .. vim.fn.fnamemodify(current_project, ":t"))
  end
  
  if not current_solution and not current_project then
    utils.warn("No .NET solution or project found in current directory")
  end
end

-- Get the target to build (solution or project)
function M.get_build_target()
  return current_solution or current_project
end

-- Build the current project/solution
function M.build(configuration)
  local target = M.get_build_target()
  if not target then
    utils.error("No .NET project or solution found")
    return
  end
  
  local dotnet_config = config.get_dotnet_config()
  configuration = configuration or dotnet_config.default_configuration or "Debug"
  
  local cmd = { "dotnet", "build", target, "--configuration", configuration }
  
  utils.info("Building " .. vim.fn.fnamemodify(target, ":t") .. " (" .. configuration .. ")...")
  
  M.execute_dotnet_command(cmd, function(exit_code, output)
    if exit_code == 0 then
      utils.info("Build succeeded")
    else
      utils.error("Build failed")
      M.show_build_output(output)
    end
  end)
end

-- Run the current project
function M.run(configuration)
  local target = current_project
  if not target then
    utils.error("No .NET project found")
    return
  end
  
  local dotnet_config = config.get_dotnet_config()
  configuration = configuration or dotnet_config.default_configuration or "Debug"
  
  local cmd = { "dotnet", "run", "--project", target, "--configuration", configuration }
  
  utils.info("Running " .. vim.fn.fnamemodify(target, ":t") .. "...")
  
  -- Run in a terminal for interactive applications
  M.execute_dotnet_command_in_terminal(cmd)
end

-- Test the current project/solution
function M.test(configuration)
  local target = M.get_build_target()
  if not target then
    utils.error("No .NET project or solution found")
    return
  end
  
  local dotnet_config = config.get_dotnet_config()
  configuration = configuration or dotnet_config.default_configuration or "Debug"
  
  local cmd = { "dotnet", "test", target, "--configuration", configuration, "--verbosity", "normal" }
  
  utils.info("Running tests...")
  
  M.execute_dotnet_command(cmd, function(exit_code, output)
    if exit_code == 0 then
      utils.info("All tests passed")
    else
      utils.error("Some tests failed")
      M.show_test_output(output)
    end
  end)
end

-- Restore packages for the current project/solution
function M.restore()
  local target = M.get_build_target()
  if not target then
    utils.error("No .NET project or solution found")
    return
  end
  
  local cmd = { "dotnet", "restore", target }
  
  utils.info("Restoring packages...")
  
  M.execute_dotnet_command(cmd, function(exit_code, output)
    if exit_code == 0 then
      utils.info("Package restore completed")
    else
      utils.error("Package restore failed")
      M.show_build_output(output)
    end
  end)
end

-- Clean the current project/solution
function M.clean(configuration)
  local target = M.get_build_target()
  if not target then
    utils.error("No .NET project or solution found")
    return
  end
  
  local dotnet_config = config.get_dotnet_config()
  configuration = configuration or dotnet_config.default_configuration or "Debug"
  
  local cmd = { "dotnet", "clean", target, "--configuration", configuration }
  
  utils.info("Cleaning...")
  
  M.execute_dotnet_command(cmd, function(exit_code, output)
    if exit_code == 0 then
      utils.info("Clean completed")
    else
      utils.error("Clean failed")
      M.show_build_output(output)
    end
  end)
end

-- Execute a dotnet command and handle output
function M.execute_dotnet_command(cmd, callback)
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

-- Execute a dotnet command in a terminal window
function M.execute_dotnet_command_in_terminal(cmd)
  local cmd_str = table.concat(cmd, " ")
  
  -- Create a new terminal buffer
  vim.cmd("split")
  vim.cmd("terminal " .. cmd_str)
  vim.cmd("startinsert")
end

-- Show build output in a floating window
function M.show_build_output(output)
  local lines = {}
  for _, line in ipairs(output) do
    if line ~= "" then
      table.insert(lines, line)
    end
  end
  
  if #lines == 0 then
    return
  end
  
  -- Create floating window for output
  local buf, win = utils.create_floating_window({
    title = "Build Output",
    width = math.floor(vim.o.columns * 0.9),
    height = math.floor(vim.o.lines * 0.7),
  })
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'dotnet-output')
  
  -- Set up keymaps for the output window
  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(win, true) end, opts)
end

-- Show test output with better formatting
function M.show_test_output(output)
  local lines = {}
  local in_test_results = false
  
  for _, line in ipairs(output) do
    if line ~= "" then
      -- Highlight test results
      if line:match("Test Run") or line:match("Passed!") or line:match("Failed!") then
        in_test_results = true
      end
      
      if in_test_results then
        -- Add some formatting for test results
        if line:match("Passed") then
          line = "✓ " .. line
        elseif line:match("Failed") then
          line = "✗ " .. line
        end
      end
      
      table.insert(lines, line)
    end
  end
  
  if #lines == 0 then
    return
  end
  
  -- Create floating window for test output
  local buf, win = utils.create_floating_window({
    title = "Test Results",
    width = math.floor(vim.o.columns * 0.9),
    height = math.floor(vim.o.lines * 0.7),
  })
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'dotnet-test-output')
  
  -- Set up keymaps for the output window
  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(win, true) end, opts)
end

-- Get project information
function M.get_project_info()
  return {
    solution = current_solution,
    project = current_project,
    has_solution = current_solution ~= nil,
    has_project = current_project ~= nil,
  }
end

-- Watch for file changes and auto-restore if enabled
function M.setup_auto_restore()
  local dotnet_config = config.get_dotnet_config()
  
  if not dotnet_config.auto_restore then
    return
  end
  
  local group = vim.api.nvim_create_augroup("DotnetAutoRestore", { clear = true })
  
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    pattern = { "*.csproj", "*.fsproj", "*.vbproj", "*.sln" },
    callback = function()
      utils.info("Project file changed, restoring packages...")
      M.restore()
    end,
  })
end

return M
