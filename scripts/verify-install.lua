-- scripts/verify-install.lua
-- Quick verification script to check if the plugin is properly installed

local function check_module(name)
  local ok, module = pcall(require, name)
  if ok then
    print("✓ " .. name .. " loaded successfully")
    return true
  else
    print("✗ Failed to load " .. name .. ": " .. tostring(module))
    return false
  end
end

local function main()
  print("dotnet-core.nvim Installation Verification")
  print("==========================================")
  
  -- Check if Neovim version is compatible
  if vim.fn.has('nvim-0.8.0') == 1 then
    print("✓ Neovim version is compatible (>= 0.8.0)")
  else
    print("✗ Neovim version is too old. Requires >= 0.8.0")
    return false
  end
  
  -- Check main module
  if not check_module('dotnet-core') then
    return false
  end
  
  -- Check all submodules
  local modules = {
    'dotnet-core.config',
    'dotnet-core.utils',
    'dotnet-core.lsp',
    'dotnet-core.dotnet',
    'dotnet-core.commands',
    'dotnet-core.keymaps',
    'dotnet-core.health',
    'dotnet-core.project',
    'dotnet-core.debug'
  }
  
  local all_ok = true
  for _, module_name in ipairs(modules) do
    if not check_module(module_name) then
      all_ok = false
    end
  end
  
  if not all_ok then
    return false
  end
  
  -- Try to setup the plugin
  print("\nTesting plugin setup...")
  local setup_ok, setup_err = pcall(function()
    require('dotnet-core').setup({
      keymaps = { enable_default = false },
      dotnet = { auto_restore = false },
    })
  end)
  
  if setup_ok then
    print("✓ Plugin setup completed successfully")
  else
    print("✗ Plugin setup failed: " .. tostring(setup_err))
    return false
  end
  
  print("\n🎉 dotnet-core.nvim is properly installed!")
  print("\nNext steps:")
  print("1. Run :DotnetCoreHealth to check your .NET environment")
  print("2. Navigate to a .NET project and start coding!")
  print("3. Use :help dotnet-core for documentation")
  
  return true
end

-- Run the verification
main()
