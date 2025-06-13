-- dotnet-core/init.lua - Main plugin initialization
-- Provides Visual Studio-like functionality for .NET Core development in Neovim

local M = {}

-- Default configuration
local default_config = {
  -- LSP configuration
  lsp = {
    -- Language server type: "auto", "roslyn", "csharp_ls", or "omnisharp"
    server_type = "auto", -- Auto-detect best available server

    -- Roslyn Language Server (Microsoft's official - fastest and most reliable)
    roslyn = {
      cmd = { "Microsoft.CodeAnalysis.LanguageServer" },
    },

    -- csharp-ls (lightweight alternative)
    csharp_ls = {
      cmd = { "csharp-ls" },
    },

    -- OmniSharp (traditional option)
    omnisharp = {
      cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
      enable_roslyn_analyzers = true,
      enable_import_completion = true,
      organize_imports_on_format = true,
      enable_decompilation_support = true,
    },
  },
  
  -- Dotnet CLI configuration
  dotnet = {
    auto_restore = true,
    build_on_save = false,
    test_on_save = false,
    default_configuration = "Debug",
    default_framework = nil, -- Auto-detect
  },
  
  -- UI configuration
  ui = {
    use_floating_windows = true,
    border = "rounded",
    transparency = 10,
    icons = {
      class = "󰠱",
      interface = "",
      method = "󰊕",
      property = "",
      field = "󰜢",
      enum = "",
      namespace = "󰌗",
      project = "",
      solution = "",
    },
  },
  
  -- Keybindings
  keymaps = {
    enable_default = true,
    leader = "<leader>", -- Direct leader access for speed
    visual_studio_style = true, -- Enable Visual Studio-style keybindings for C# files
    mappings = {
      -- Single key shortcuts (super fast!)
      build = "b",           -- <leader>b - Build (most common)
      run = "r",             -- <leader>r - Run (most common)
      test = "t",            -- <leader>t - Test
      clean = "c",           -- <leader>c - Clean

      -- Two key shortcuts for less common actions
      restore = "pr",        -- <leader>pr - Package Restore
      find_references = "fr", -- <leader>fr - Find References
      go_to_implementation = "gi", -- <leader>gi - Go Implementation
      rename = "rn",         -- <leader>rn - Rename
      code_action = "ca",    -- <leader>ca - Code Action
      solution_explorer = "se", -- <leader>se - Solution Explorer
      project_structure = "ps", -- <leader>ps - Project Structure
      new_project = "np",    -- <leader>np - New Project
      add_package = "pa",    -- <leader>pa - Package Add
      remove_package = "pd", -- <leader>pd - Package Delete
      startup_project = "sp", -- <leader>sp - Select Startup Project
      health = "h",          -- <leader>h - Health check
    },
  },
  
  -- Debug configuration
  debug = {
    adapter = "netcoredbg",
    console = "integratedTerminal",
    stopOnEntry = false,
  },
  
  -- Project management
  project = {
    auto_detect_solution = true,
    show_hidden_files = false,
    group_by_project = true,
    auto_detect_startup_project = true, -- Automatically detect executable projects as startup
    startup_project = nil, -- Path to the startup project (auto-detected or manually set)
  },
}

-- Plugin state
local state = {
  config = {},
  lsp_attached = false,
  current_solution = nil,
  current_project = nil,
  startup_project = nil, -- The project to run when using run commands
}

-- Setup function
function M.setup(user_config)
  -- Merge user config with defaults
  state.config = vim.tbl_deep_extend("force", default_config, user_config or {})
  
  -- Initialize components
  require('dotnet-core.config').setup(state.config)
  require('dotnet-core.lsp').setup(state.config.lsp)
  require('dotnet-core.dotnet').setup(state.config.dotnet)
  require('dotnet-core.project').setup()
  require('dotnet-core.commands').setup()
  
  -- Set up keymaps if enabled
  if state.config.keymaps.enable_default then
    require('dotnet-core.keymaps').setup(state.config.keymaps)
    -- Also set up keymap autocommands for buffer-local keymaps
    require('dotnet-core.keymaps').setup_autocommands()
  end

  -- Auto-detect .NET projects
  if state.config.project.auto_detect_solution then
    M.detect_project()
  end

  -- Set up autocommands
  M.setup_autocommands()
  
  print("dotnet-core.nvim initialized successfully!")
end

-- Auto-detect .NET projects in the current workspace
function M.detect_project()
  local utils = require('dotnet-core.utils')
  local cwd = vim.fn.getcwd()
  
  -- Look for solution files
  local solution_files = utils.find_files(cwd, "*.sln")
  if #solution_files > 0 then
    state.current_solution = solution_files[1]
    print("Detected .NET solution: " .. vim.fn.fnamemodify(state.current_solution, ":t"))
  end
  
  -- Look for project files
  local project_files = utils.find_files(cwd, "*.csproj")
  if #project_files > 0 then
    state.current_project = project_files[1]
    print("Detected .NET project: " .. vim.fn.fnamemodify(state.current_project, ":t"))
  end
end

-- Set up autocommands for the plugin
function M.setup_autocommands()
  local group = vim.api.nvim_create_augroup("DotnetCore", { clear = true })
  
  -- Auto-restore packages when project files change
  if state.config.dotnet.auto_restore then
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = group,
      pattern = { "*.csproj", "*.fsproj", "*.vbproj" },
      callback = function()
        require('dotnet-core.dotnet').restore()
      end,
    })
  end
  
  -- Auto-build on save if enabled
  if state.config.dotnet.build_on_save then
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = group,
      pattern = { "*.cs", "*.fs", "*.vb" },
      callback = function()
        require('dotnet-core.dotnet').build()
      end,
    })
  end
  
  -- Auto-test on save if enabled
  if state.config.dotnet.test_on_save then
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = group,
      pattern = { "*Test.cs", "*Tests.cs", "*.Test.cs", "*.Tests.cs" },
      callback = function()
        require('dotnet-core.dotnet').test()
      end,
    })
  end
  
  -- Set up LSP when entering C# files
  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = group,
    pattern = { "cs", "fs", "vb" },
    callback = function()
      require('dotnet-core.lsp').attach_to_buffer()
    end,
  })
end

-- Get current plugin state
function M.get_state()
  return state
end

-- Get current configuration
function M.get_config()
  return state.config
end

return M
