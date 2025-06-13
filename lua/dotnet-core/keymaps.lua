-- dotnet-core/keymaps.lua - Keybinding setup for the plugin

local M = {}
local utils = require('dotnet-core.utils')

-- Setup keymaps based on configuration
function M.setup(keymap_config)
  if not keymap_config.enable_default then
    return
  end
  
  local leader = keymap_config.leader or "<leader>d"
  local mappings = keymap_config.mappings or {}
  
  -- Create keymaps for dotnet commands
  M.create_dotnet_keymaps(leader, mappings)
  
  -- Create keymaps for LSP functions
  M.create_lsp_keymaps(leader, mappings)
  
  -- Create keymaps for project management
  M.create_project_keymaps(leader, mappings)
  
  -- Create keymaps for debugging
  M.create_debug_keymaps(leader, mappings)
  
  utils.info("Keymaps configured with leader: " .. leader)
end

-- Create keymaps for dotnet CLI commands
function M.create_dotnet_keymaps(leader, mappings)
  local opts = { noremap = true, silent = true, desc = "" }

  -- Build commands
  if mappings.build then
    opts.desc = "Build .NET project/solution"
    vim.keymap.set('n', leader .. mappings.build, '<cmd>DotnetCoreBuild<cr>', opts)
  end

  -- Run commands
  if mappings.run then
    opts.desc = "Run .NET project"
    vim.keymap.set('n', leader .. mappings.run, '<cmd>DotnetCoreRun<cr>', opts)
  end

  -- Test commands
  if mappings.test then
    opts.desc = "Run .NET tests"
    vim.keymap.set('n', leader .. mappings.test, '<cmd>DotnetCoreTest<cr>', opts)
  end

  -- Restore packages
  if mappings.restore then
    opts.desc = "Restore NuGet packages"
    vim.keymap.set('n', leader .. mappings.restore, '<cmd>DotnetCoreRestore<cr>', opts)
  end

  -- Clean
  if mappings.clean then
    opts.desc = "Clean .NET project/solution"
    vim.keymap.set('n', leader .. mappings.clean, '<cmd>DotnetCoreClean<cr>', opts)
  end
  
  -- Additional build configurations
  opts.desc = "Build Debug configuration"
  vim.keymap.set('n', leader .. 'bd', '<cmd>DotnetCoreBuild Debug<cr>', opts)
  
  opts.desc = "Build Release configuration"
  vim.keymap.set('n', leader .. 'br', '<cmd>DotnetCoreBuild Release<cr>', opts)
  
  opts.desc = "Run Debug configuration"
  vim.keymap.set('n', leader .. 'rd', '<cmd>DotnetCoreRun Debug<cr>', opts)
  
  opts.desc = "Run Release configuration"
  vim.keymap.set('n', leader .. 'rr', '<cmd>DotnetCoreRun Release<cr>', opts)
end

-- Create keymaps for LSP functions
function M.create_lsp_keymaps(leader, mappings)
  local opts = { noremap = true, silent = true, desc = "" }
  
  -- Find references
  if mappings.find_references then
    opts.desc = "Find all references"
    vim.keymap.set('n', leader .. mappings.find_references, '<cmd>DotnetCoreFindReferences<cr>', opts)
  end
  
  -- Go to implementation
  if mappings.go_to_implementation then
    opts.desc = "Go to implementation"
    vim.keymap.set('n', leader .. mappings.go_to_implementation, '<cmd>DotnetCoreGoToImplementation<cr>', opts)
  end
  
  -- Rename symbol
  if mappings.rename then
    opts.desc = "Rename symbol"
    vim.keymap.set('n', leader .. mappings.rename, '<cmd>DotnetCoreRename<cr>', opts)
  end
  
  -- Code actions
  if mappings.code_action then
    opts.desc = "Show code actions"
    vim.keymap.set('n', leader .. mappings.code_action, '<cmd>DotnetCoreCodeAction<cr>', opts)
  end
  
  -- Additional LSP keymaps for .NET specific features
  opts.desc = "Go to definition"
  vim.keymap.set('n', leader .. 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
  
  opts.desc = "Go to declaration"
  vim.keymap.set('n', leader .. 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
  
  opts.desc = "Show hover information"
  vim.keymap.set('n', leader .. 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
  
  opts.desc = "Show signature help"
  vim.keymap.set('n', leader .. 'sh', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
  
  opts.desc = "Format document"
  vim.keymap.set('n', leader .. 'f', '<cmd>lua vim.lsp.buf.format({ async = true })<cr>', opts)
  
  -- Diagnostics
  opts.desc = "Show line diagnostics"
  vim.keymap.set('n', leader .. 'e', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
  
  opts.desc = "Go to previous diagnostic"
  vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
  
  opts.desc = "Go to next diagnostic"
  vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)
  
  opts.desc = "Set location list with diagnostics"
  vim.keymap.set('n', leader .. 'q', '<cmd>lua vim.diagnostic.setloclist()<cr>', opts)
end

-- Create keymaps for project management
function M.create_project_keymaps(leader, mappings)
  local opts = { noremap = true, silent = true, desc = "" }
  
  -- Solution explorer
  if mappings.solution_explorer then
    opts.desc = "Open solution explorer"
    vim.keymap.set('n', leader .. mappings.solution_explorer, '<cmd>DotnetCoreSolutionExplorer<cr>', opts)
  end

  -- Project structure
  if mappings.project_structure then
    opts.desc = "Show project structure"
    vim.keymap.set('n', leader .. mappings.project_structure, '<cmd>DotnetCoreProjectStructure<cr>', opts)
  end

  -- Startup project selection
  if mappings.startup_project then
    opts.desc = "Select startup project"
    vim.keymap.set('n', leader .. mappings.startup_project, '<cmd>DotnetCoreSelectStartupProject<cr>', opts)
  end
  
  -- Additional project management keymaps
  opts.desc = "Create new project"
  vim.keymap.set('n', leader .. 'np', '<cmd>DotnetCoreNewProject<cr>', opts)

  opts.desc = "Create new solution"
  vim.keymap.set('n', leader .. 'ns', '<cmd>DotnetCoreNewSolution<cr>', opts)

  opts.desc = "Add NuGet package"
  vim.keymap.set('n', leader .. 'ap', '<cmd>DotnetCoreAddPackage<cr>', opts)

  opts.desc = "Remove NuGet package"
  vim.keymap.set('n', leader .. 'rp', '<cmd>DotnetCoreRemovePackage<cr>', opts)

  opts.desc = "Check plugin health"
  vim.keymap.set('n', leader .. 'h', '<cmd>DotnetCoreHealth<cr>', opts)

  -- === GLOBAL VISUAL STUDIO STYLE KEYMAPS ===

  -- Solution Explorer (VS: Ctrl+Alt+L) - Alternative: Ctrl+E
  opts.desc = "Solution Explorer (VS: Ctrl+Alt+L) - Alternative: Ctrl+E"
  vim.keymap.set('n', '<C-e>', '<cmd>DotnetCoreSolutionExplorer<cr>', opts)

  -- Build shortcuts (global, work in any buffer)
  opts.desc = "Build Solution (VS: Ctrl+Shift+B)"
  vim.keymap.set('n', '<C-S-B>', '<cmd>DotnetCoreBuild<cr>', opts)

  opts.desc = "Rebuild Solution (VS: Ctrl+Alt+F7)"
  vim.keymap.set('n', '<C-A-F7>', '<cmd>DotnetCoreClean<cr><cmd>DotnetCoreBuild<cr>', opts)
end

-- Create keymaps for debugging
function M.create_debug_keymaps(leader, mappings)
  local opts = { noremap = true, silent = true, desc = "" }
  
  -- Debug start/stop
  opts.desc = "Start debugging"
  vim.keymap.set('n', leader .. 'ds', '<cmd>DotnetCoreDebugStart<cr>', opts)
  
  opts.desc = "Stop debugging"
  vim.keymap.set('n', leader .. 'dq', '<cmd>DotnetCoreDebugStop<cr>', opts)
  
  -- Breakpoints
  opts.desc = "Toggle breakpoint"
  vim.keymap.set('n', leader .. 'db', '<cmd>DotnetCoreDebugToggleBreakpoint<cr>', opts)
  
  -- Step debugging (these will be implemented in debug module)
  opts.desc = "Debug step over"
  vim.keymap.set('n', '<F10>', '<cmd>lua require("dotnet-core.debug").step_over()<cr>', opts)
  
  opts.desc = "Debug step into"
  vim.keymap.set('n', '<F11>', '<cmd>lua require("dotnet-core.debug").step_into()<cr>', opts)
  
  opts.desc = "Debug step out"
  vim.keymap.set('n', '<S-F11>', '<cmd>lua require("dotnet-core.debug").step_out()<cr>', opts)
  
  opts.desc = "Debug continue"
  vim.keymap.set('n', '<F5>', '<cmd>lua require("dotnet-core.debug").continue()<cr>', opts)
end

-- Create buffer-local keymaps for .NET files (Visual Studio style)
function M.setup_buffer_keymaps(bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr, desc = "" }

  -- === VISUAL STUDIO STYLE KEYBINDINGS ===

  -- Build & Run (Visual Studio defaults)
  opts.desc = "Start Debugging/Run (VS: F5)"
  vim.keymap.set('n', '<F5>', '<cmd>DotnetCoreRun<cr>', opts)

  opts.desc = "Start Without Debugging (VS: Ctrl+F5)"
  vim.keymap.set('n', '<C-F5>', '<cmd>DotnetCoreRun<cr>', opts)

  opts.desc = "Build Solution (VS: F6)"
  vim.keymap.set('n', '<F6>', '<cmd>DotnetCoreBuild<cr>', opts)

  opts.desc = "Build Solution (VS: Ctrl+Shift+B)"
  vim.keymap.set('n', '<C-S-B>', '<cmd>DotnetCoreBuild<cr>', opts)

  -- Navigation (Visual Studio defaults)
  opts.desc = "Go to Definition (VS: F12)"
  vim.keymap.set('n', '<F12>', function() vim.lsp.buf.definition() end, opts)

  opts.desc = "Go to Implementation (VS: Ctrl+F12)"
  vim.keymap.set('n', '<C-F12>', function() vim.lsp.buf.implementation() end, opts)

  opts.desc = "Find All References (VS: Shift+F12)"
  vim.keymap.set('n', '<S-F12>', function() vim.lsp.buf.references() end, opts)

  opts.desc = "Rename Symbol (VS: F2)"
  vim.keymap.set('n', '<F2>', function() vim.lsp.buf.rename() end, opts)

  opts.desc = "Quick Actions/Code Actions (VS: Ctrl+.)"
  vim.keymap.set('n', '<C-.>', function() vim.lsp.buf.code_action() end, opts)

  opts.desc = "Quick Info/Hover (VS: Ctrl+K, Ctrl+I) - Alternative: Ctrl+H"
  vim.keymap.set('n', '<C-h>', function() vim.lsp.buf.hover() end, opts)

  opts.desc = "Parameter Info (VS: Ctrl+Shift+Space)"
  vim.keymap.set('n', '<C-S-Space>', function() vim.lsp.buf.signature_help() end, opts)

  -- Debugging (Visual Studio defaults)
  opts.desc = "Toggle Breakpoint (VS: F9)"
  vim.keymap.set('n', '<F9>', '<cmd>DotnetCoreDebugToggleBreakpoint<cr>', opts)

  opts.desc = "Step Over (VS: F10)"
  vim.keymap.set('n', '<F10>', '<cmd>lua require("dotnet-core.debug").step_over()<cr>', opts)

  opts.desc = "Step Into (VS: F11)"
  vim.keymap.set('n', '<F11>', '<cmd>lua require("dotnet-core.debug").step_into()<cr>', opts)

  opts.desc = "Step Out (VS: Shift+F11)"
  vim.keymap.set('n', '<S-F11>', '<cmd>lua require("dotnet-core.debug").step_out()<cr>', opts)

  -- === NEOVIM TRADITIONAL KEYBINDINGS (for compatibility) ===

  opts.desc = "Go to definition (Neovim: gd)"
  vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)

  opts.desc = "Find references (Neovim: gr)"
  vim.keymap.set('n', 'gr', function() vim.lsp.buf.references() end, opts)

  opts.desc = "Go to implementation (Neovim: gi)"
  vim.keymap.set('n', 'gi', function() vim.lsp.buf.implementation() end, opts)

  opts.desc = "Hover information (Neovim: K)"
  vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)

  -- === ADDITIONAL USEFUL KEYBINDINGS ===

  opts.desc = "Run Tests"
  vim.keymap.set('n', '<C-T>', '<cmd>DotnetCoreTest<cr>', opts)

  opts.desc = "Solution Explorer (VS: Ctrl+Alt+L) - Alternative: Ctrl+E"
  vim.keymap.set('n', '<C-e>', '<cmd>DotnetCoreSolutionExplorer<cr>', opts)

  opts.desc = "Format Document (VS: Ctrl+K, Ctrl+D) - Alternative: Ctrl+F"
  vim.keymap.set('n', '<C-f>', function() vim.lsp.buf.format({ async = true }) end, opts)
end

-- Setup autocommands for buffer-local keymaps
function M.setup_autocommands()
  local group = vim.api.nvim_create_augroup("DotnetCoreKeymaps", { clear = true })
  
  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = group,
    pattern = { "cs", "fs", "vb" },
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      M.setup_buffer_keymaps(bufnr)
    end,
  })
end

-- Get keymap information for help
function M.get_keymap_info()
  local config = require('dotnet-core.config')
  local keymap_config = config.get_keymaps_config()
  
  if not keymap_config.enable_default then
    return "Default keymaps are disabled"
  end
  
  local leader = keymap_config.leader or "<leader>d"
  local mappings = keymap_config.mappings or {}
  
  local info = {
    leader = leader,
    dotnet_commands = {},
    lsp_commands = {},
    project_commands = {},
    debug_commands = {},
  }
  
  -- Build dotnet command info
  if mappings.build then
    table.insert(info.dotnet_commands, { key = leader .. mappings.build, desc = "Build project/solution" })
  end
  if mappings.run then
    table.insert(info.dotnet_commands, { key = leader .. mappings.run, desc = "Run project" })
  end
  if mappings.test then
    table.insert(info.dotnet_commands, { key = leader .. mappings.test, desc = "Run tests" })
  end
  
  -- Build LSP command info
  if mappings.find_references then
    table.insert(info.lsp_commands, { key = leader .. mappings.find_references, desc = "Find references" })
  end
  if mappings.go_to_implementation then
    table.insert(info.lsp_commands, { key = leader .. mappings.go_to_implementation, desc = "Go to implementation" })
  end
  
  return info
end

return M
