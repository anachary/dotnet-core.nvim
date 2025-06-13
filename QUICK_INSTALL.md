# Quick Installation Guide

## ✅ Plugin Successfully Tested!

The dotnet-core.nvim plugin has been tested and is working perfectly with:
- ✅ Neovim 0.11.2
- ✅ .NET SDK 9.0.200
- ✅ All core features verified

## 🚀 Add to Your Neovim Config

Add this to your `lazy.nvim` plugin list in `init.lua`:

```lua
{
  "anachary/dotnet-core.nvim", -- GitHub repository
  -- OR for local development:
  -- dir = "C:/Users/akash/code/git-repos/dotnet-core.nvim", -- Local path
  name = "dotnet-core.nvim",
  dependencies = { 
    "neovim/nvim-lspconfig",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  ft = { "cs", "fs", "vb" }, -- Load for .NET files only
  config = function()
    require("dotnet-core").setup({
      keymaps = {
        enable_default = true,
        leader = "<leader>d", -- Use <leader>d prefix
      },
      dotnet = {
        auto_restore = true,
        build_on_save = false,
        default_configuration = "Debug",
      },
    })
  end,
},
```

## 🎯 Key Commands

- `:DotnetCoreHealth` - Check plugin status
- `<leader>db` - Build project
- `<leader>dr` - Run project
- `<leader>dse` - Solution explorer
- `<leader>dnp` - New project

## 📋 Next Steps

1. Install OmniSharp: `:MasonInstall omnisharp`
2. Navigate to any .NET project
3. Run `:DotnetCoreHealth` to verify
4. Start coding! 🚀
