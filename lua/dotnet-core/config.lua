-- dotnet-core/config.lua - Configuration management for the plugin

local M = {}

-- Plugin configuration state
local config = {}

-- Setup configuration
function M.setup(user_config)
  config = user_config
end

-- Get configuration value with optional default
function M.get(key, default)
  local keys = vim.split(key, ".", { plain = true })
  local value = config
  
  for _, k in ipairs(keys) do
    if type(value) == "table" and value[k] ~= nil then
      value = value[k]
    else
      return default
    end
  end
  
  return value
end

-- Set configuration value
function M.set(key, value)
  local keys = vim.split(key, ".", { plain = true })
  local current = config
  
  for i = 1, #keys - 1 do
    local k = keys[i]
    if type(current[k]) ~= "table" then
      current[k] = {}
    end
    current = current[k]
  end
  
  current[keys[#keys]] = value
end

-- Get the entire configuration
function M.get_all()
  return config
end

-- Validate configuration
function M.validate()
  local errors = {}
  
  -- Validate LSP configuration
  if config.lsp and config.lsp.omnisharp then
    if not config.lsp.omnisharp.cmd or type(config.lsp.omnisharp.cmd) ~= "table" then
      table.insert(errors, "lsp.omnisharp.cmd must be a table")
    end
  end
  
  -- Validate dotnet configuration
  if config.dotnet then
    if config.dotnet.default_configuration and 
       not vim.tbl_contains({"Debug", "Release"}, config.dotnet.default_configuration) then
      table.insert(errors, "dotnet.default_configuration must be 'Debug' or 'Release'")
    end
  end
  
  -- Validate UI configuration
  if config.ui then
    if config.ui.border and 
       not vim.tbl_contains({"none", "single", "double", "rounded", "solid", "shadow"}, config.ui.border) then
      table.insert(errors, "ui.border must be a valid border style")
    end
    
    if config.ui.transparency and 
       (type(config.ui.transparency) ~= "number" or config.ui.transparency < 0 or config.ui.transparency > 100) then
      table.insert(errors, "ui.transparency must be a number between 0 and 100")
    end
  end
  
  -- Validate keymaps configuration
  if config.keymaps then
    if config.keymaps.leader and type(config.keymaps.leader) ~= "string" then
      table.insert(errors, "keymaps.leader must be a string")
    end
    
    if config.keymaps.mappings and type(config.keymaps.mappings) ~= "table" then
      table.insert(errors, "keymaps.mappings must be a table")
    end
  end
  
  return #errors == 0, errors
end

-- Get LSP configuration for OmniSharp
function M.get_lsp_config()
  local lsp_config = config.lsp or {}
  local omnisharp_config = lsp_config.omnisharp or {}
  
  return {
    cmd = omnisharp_config.cmd or { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
    filetypes = { "cs", "vb" },
    root_dir = function(fname)
      local util = require('lspconfig.util')
      return util.root_pattern("*.sln", "*.csproj", ".git")(fname)
    end,
    settings = {
      FormattingOptions = {
        EnableEditorConfigSupport = true,
        OrganizeImports = omnisharp_config.organize_imports_on_format or true,
      },
      MsBuild = {
        LoadProjectsOnDemand = false,
      },
      RoslynExtensionsOptions = {
        EnableAnalyzersSupport = omnisharp_config.enable_roslyn_analyzers or true,
        EnableImportCompletion = omnisharp_config.enable_import_completion or true,
        EnableDecompilationSupport = omnisharp_config.enable_decompilation_support or true,
      },
    },
    init_options = {
      AutomaticWorkspaceInit = true,
    },
  }
end

-- Get dotnet CLI configuration
function M.get_dotnet_config()
  return config.dotnet or {}
end

-- Get UI configuration
function M.get_ui_config()
  return config.ui or {}
end

-- Get keymaps configuration
function M.get_keymaps_config()
  return config.keymaps or {}
end

-- Get debug configuration
function M.get_debug_config()
  return config.debug or {}
end

-- Get project configuration
function M.get_project_config()
  return config.project or {}
end

-- Export configuration for external use
function M.export()
  return vim.deepcopy(config)
end

-- Import configuration from external source
function M.import(external_config)
  if type(external_config) == "table" then
    config = vim.tbl_deep_extend("force", config, external_config)
    return true
  end
  return false
end

-- Reset configuration to defaults
function M.reset()
  config = {}
end

return M
