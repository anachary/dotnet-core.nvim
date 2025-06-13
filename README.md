# dotnet-core.nvim

A comprehensive Neovim plugin that provides Visual Studio-like functionality specifically for .NET Core development, with a focus on superior user experience and keyboard-driven workflow.

[![LuaRocks](https://img.shields.io/luarocks/v/anachary/dotnet-core.nvim?logo=lua&color=purple)](https://luarocks.org/modules/anachary/dotnet-core.nvim)

## 🚦 Implementation Status

**✅ Fully Implemented:**
- LSP Integration (OmniSharp/Roslyn)
- Build System (dotnet CLI commands)
- Project Management & Solution Explorer
- Code Navigation & Refactoring
- Health Check System
- Configuration Management
- Keybinding System
- Project Templates & Creation
- NuGet Package Management

**🟡 Experimental/Basic:**
- Debugging Support (requires nvim-dap, basic functionality only)

**📋 Planned:**
- Advanced debugging features (variable inspection, call stack)
- Enhanced UI themes
- Additional project management features

> **TL;DR**: This plugin is production-ready for .NET development! All core features are implemented and working. Only advanced debugging features are still in development.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Configuration](#configuration)
- [Commands](#commands)
- [Keybindings](#keybindings)
- [Project Templates](#project-templates)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

### 🚀 Core Functionality
- **LSP Integration**: Full OmniSharp/Roslyn integration for C# language support ✅
- **Build System**: Integrated dotnet CLI with build, run, test, and restore commands ✅
- **Project Management**: Solution explorer and project structure visualization ✅
- **Code Navigation**: Enhanced go-to-definition, find references, and go-to-implementation ✅
- **Refactoring**: Rename symbols, code actions, and quick fixes ✅
- **Debugging**: Basic nvim-dap integration for .NET Core debugging 🟡 (experimental)

### 🎯 .NET Core Focused
- Auto-detection of .NET solutions and projects ✅
- Support for multiple target frameworks ✅
- NuGet package management integration ✅
- Project template creation ✅
- Configuration-aware builds (Debug/Release) ✅

### ⌨️ Keyboard-First Design
- Comprehensive keybinding system ✅
- Command palette integration ✅
- Context-aware commands ✅
- Minimal UI with floating windows ✅

## Requirements

- **Neovim 0.8.0+** - Required for LSP and Lua features
- **.NET SDK** - Required for building and running projects
- **OmniSharp** - Language server for C# (auto-installed via Mason)

### Optional Dependencies
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Enhanced UI for pickers
- [mfussenegger/nvim-dap](https://github.com/mfussenegger/nvim-dap) - Debugging support (experimental)
- [williamboman/mason.nvim](https://github.com/williamboman/mason.nvim) - Easy OmniSharp installation

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  "anachary/dotnet-core.nvim",
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    require("dotnet-core").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "anachary/dotnet-core.nvim",
  requires = { "neovim/nvim-lspconfig" },
  config = function()
    require("dotnet-core").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'anachary/dotnet-core.nvim'

" In your init.vim or init.lua
lua require("dotnet-core").setup()
```

### Install OmniSharp (Language Server)

**Option 1: Using Mason (Recommended)**
```vim
:MasonInstall omnisharp
```

**Option 2: Manual Installation**
- Download from [OmniSharp releases](https://github.com/OmniSharp/omnisharp-roslyn/releases)
- Extract and add to your PATH

## Quick Start

1. **Install the plugin** using your preferred package manager
2. **Install .NET SDK** from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download)
3. **Install OmniSharp**: `:MasonInstall omnisharp`
4. **Verify installation**: `:DotnetCoreHealth`
5. **Create a test project**:
   ```bash
   mkdir my-project && cd my-project
   dotnet new console
   nvim Program.cs
   ```
6. **Try basic commands**: `:DotnetCoreBuild`, `:DotnetCoreRun`

## Usage

### Basic Workflow

```vim
" Create new project
:DotnetCoreNewProject console

" Build and run
:DotnetCoreBuild
:DotnetCoreRun

" Explore project structure
:DotnetCoreSolutionExplorer

" Add NuGet packages
:DotnetCoreAddPackage Newtonsoft.Json
```

### LSP Features

The plugin automatically configures OmniSharp for rich C# language support:

- **Autocomplete**: Just start typing
- **Go to definition**: `gd`
- **Find references**: `gr`
- **Hover information**: `K`
- **Rename symbol**: `<F2>`
- **Code actions**: `<leader>ca`

## Configuration

### Default Configuration

```lua
require("dotnet-core").setup({
  -- LSP configuration
  lsp = {
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
    mappings = {
      build = "b",
      run = "r",
      test = "t",
      restore = "R",
      clean = "c",
      find_references = "fr",
      go_to_implementation = "gi",
      rename = "rn",
      code_action = "ca",
      solution_explorer = "se",
      project_structure = "ps",
    },
  },
})
```

### Custom Configuration Examples

**Change leader key prefix:**
```lua
require("dotnet-core").setup({
  keymaps = {
    leader = "<leader>", -- Use direct leader for fastest access
  },
})
```

**Disable auto-features:**
```lua
require("dotnet-core").setup({
  dotnet = {
    auto_restore = false,    -- Disable auto-restore on project file changes
    build_on_save = false,   -- Disable auto-build on save
    test_on_save = false,    -- Disable auto-test on save
  },
})
```

**Custom LSP settings:**
```lua
require("dotnet-core").setup({
  lsp = {
    omnisharp = {
      cmd = { "/path/to/omnisharp", "--languageserver" },
      enable_roslyn_analyzers = true,
      enable_import_completion = true,
      organize_imports_on_format = true,
      enable_decompilation_support = true,
    },
  },
})
```

## Commands

### Project Management
- `:DotnetCoreNewProject [template]` - Create a new .NET project ✅
- `:DotnetCoreNewSolution [name]` - Create a new .NET solution ✅
- `:DotnetCoreSolutionExplorer` - Open solution explorer ✅
- `:DotnetCoreProjectStructure` - Show detailed project structure ✅

### Build & Run
- `:DotnetCoreBuild [config]` - Build project/solution ✅
- `:DotnetCoreRun [config]` - Run the startup project ✅
- `:DotnetCoreTest [config]` - Run tests ✅
- `:DotnetCoreRestore` - Restore NuGet packages ✅
- `:DotnetCoreClean [config]` - Clean build artifacts ✅

### Startup Project Management
- `:DotnetCoreSelectStartupProject` - Select which project to run ✅
- `:DotnetCoreSetStartupProject [path]` - Set specific project as startup ✅

### Code Navigation & LSP
- `:DotnetCoreFindReferences` - Find all references to symbol ✅
- `:DotnetCoreGoToImplementation` - Go to implementation ✅
- `:DotnetCoreRename` - Rename symbol ✅
- `:DotnetCoreCodeAction` - Show available code actions ✅

### Package Management
- `:DotnetCoreAddPackage <name>` - Add NuGet package
- `:DotnetCoreRemovePackage <name>` - Remove NuGet package

### Debugging (Experimental)
- `:DotnetCoreDebugStart` - Start debugging 🟡 (requires nvim-dap)
- `:DotnetCoreDebugStop` - Stop debugging 🟡 (requires nvim-dap)
- `:DotnetCoreDebugToggleBreakpoint` - Toggle breakpoint 🟡 (requires nvim-dap)

**Note**: Debugging is experimental and requires nvim-dap to be installed and configured.

### Utility
- `:DotnetCoreHealth` - Check plugin health ✅
- `:DotnetCoreSetup` - Reinitialize plugin ✅

## Keybindings

**Super fast shortcuts!** Most common actions are single key presses. All keybindings are configurable.

### Build & Run (Single Key - Super Fast! ⚡)
- `<leader>b` - **B**uild project/solution
- `<leader>r` - **R**un project
- `<leader>t` - **T**est
- `<leader>c` - **C**lean
- `<leader>pr` - **P**ackage **R**estore

### Build Configurations (Two Keys)
- `<leader>bd` - **B**uild **D**ebug
- `<leader>br` - **B**uild **R**elease
- `<leader>rd` - **R**un **D**ebug
- `<leader>rr` - **R**un **R**elease

### Code Navigation (Two Keys)
- `<leader>fr` - **F**ind **R**eferences
- `<leader>gi` - **G**o to **I**mplementation
- `<leader>rn` - **R**e**n**ame symbol
- `<leader>ca` - **C**ode **A**ctions
- `gd` - Go to definition (buffer-local)
- `gr` - Find references (buffer-local)
- `gi` - Go to implementation (buffer-local)
- `<F2>` - Rename (buffer-local)

### Project Management (Two Keys)
- `<leader>se` - **S**olution **E**xplorer
- `<leader>ps` - **P**roject **S**tructure
- `<leader>sp` - **S**tartup **P**roject selection
- `<leader>np` - **N**ew **P**roject
- `<leader>ns` - **N**ew **S**olution
- `<leader>pa` - **P**ackage **A**dd
- `<leader>pd` - **P**ackage **D**elete

### Utility (Single Key)
- `<leader>h` - **H**ealth check

### Quick Actions (Visual Studio Style)
**Build & Run:**
- `<F5>` - Start Debugging/Run (VS style)
- `<Ctrl+F5>` - Start Without Debugging (VS style)
- `<F6>` - Build Solution (VS style)
- `<Ctrl+Shift+B>` - Build Solution (VS style)

**Navigation:**
- `<F12>` - Go to Definition (VS style)
- `<Ctrl+F12>` - Go to Implementation (VS style)
- `<Shift+F12>` - Find All References (VS style)
- `<F2>` - Rename Symbol (VS style)
- `<Ctrl+.>` - Quick Actions/Code Actions (VS style)

**Information:**
- `<Ctrl+H>` - Quick Info/Hover (VS: Ctrl+K, Ctrl+I alternative)
- `<Ctrl+Shift+Space>` - Parameter Info (VS style)

**Debugging:**
- `<F9>` - Toggle Breakpoint (VS style)
- `<F10>` - Step Over (VS style)
- `<F11>` - Step Into (VS style)
- `<Shift+F11>` - Step Out (VS style)

**Solution Management:**
- `<Ctrl+E>` - Solution Explorer (VS: Ctrl+Alt+L alternative)
- `<Ctrl+F>` - Format Document (VS: Ctrl+K, Ctrl+D alternative)

### Traditional Neovim Keybindings (also available)
- `gd` - Go to definition
- `gi` - Go to implementation
- `gr` - Find references
- `K` - Hover information

## Project Templates

Supported project templates for `:DotnetCoreNewProject`:

- `console` - Console application
- `classlib` - Class library
- `web` - ASP.NET Core web application
- `webapi` - ASP.NET Core Web API
- `mvc` - ASP.NET Core MVC
- `blazorserver` - Blazor Server app
- `blazorwasm` - Blazor WebAssembly app
- `worker` - Worker service
- `winforms` - Windows Forms app
- `wpf` - WPF application
- `xunit` - xUnit test project
- `nunit` - NUnit test project
- `mstest` - MSTest test project

## 🔍 Solution Explorer

The solution explorer provides a tree view of your .NET solution:

- 📁 **Solution/Workspace** - Root container
- 📦 **Projects** - Individual .NET projects
- 📚 **Package References** - NuGet packages
- 🔗 **Project References** - Inter-project dependencies
- 📄 **Source Files** - C#, F#, VB.NET files

### Explorer Navigation & Selection
**Opening Items:**
- `<CR>` or `o` - Smart open (projects → .csproj, files → editor, directories → expand/collapse)
- `<Space>` - Expand/collapse directories
- `gf` - Go to current file in explorer

**Project Operations:**
- `b` - Build project under cursor
- `R` - Run project under cursor (if executable)
- `s` - Set project under cursor as startup project

**File Operations:**
- `a` - Create new file in selected directory/project
- `d` - Delete file under cursor
- `m` - Rename file under cursor

**Navigation & View:**
- `r` - Refresh explorer
- `i` - Show item details
- `H` - Toggle hidden files
- `/` - Search/filter items
- `q` or `<Esc>` - Close explorer

**Layout Options:**
- `:DotnetCoreExplorerLayout floating` - Floating window
- `:DotnetCoreExplorerLayout side` - Side panel
- `:DotnetCoreExplorerLayout split` - Horizontal split

## 🚀 Startup Project Management

When working with solutions containing multiple executable projects, you can specify which project should be run:

### Automatic Detection
- Automatically detects executable projects (OutputType: Exe)
- Sets the first executable project as startup by default
- Shows startup project with ⭐ marker in Solution Explorer

### Manual Selection
- Use `:DotnetCoreSelectStartupProject` to choose from available projects
- Use `<leader>sp` for quick access
- In Solution Explorer, press `s` on any executable project to set it as startup

### Commands
- `:DotnetCoreSelectStartupProject` - Interactive project selection
- `:DotnetCoreSetStartupProject [path]` - Set specific project by path
- `:DotnetCoreRun` - Always runs the current startup project

## Troubleshooting

### Health Check

Run `:DotnetCoreHealth` to diagnose issues:

```vim
:DotnetCoreHealth
```

Expected output:
- ✅ Neovim version is compatible (>= 0.8.0)
- ✅ .NET Core SDK installation
- ✅ OmniSharp availability
- ✅ LSP configuration
- ✅ Optional dependencies (Telescope, nvim-dap)
- ✅ Current project detection

### Common Issues

#### Plugin not loading
**Error**: `module 'dotnet-core' not found`

**Solutions**:
1. Verify plugin installation with your package manager
2. Ensure `require("dotnet-core").setup()` is called in your config
3. Restart Neovim completely

#### LSP not working (gd, gi, gr not working)
**Symptoms**: No autocomplete, go-to-definition, implementation, or references

**Quick Fix**:
1. **Install a C# Language Server**: `:MasonInstall omnisharp`
2. **Check status**: `:DotnetCoreLspStatus`
3. **Restart Neovim** and open a `.cs` file

**Detailed Solutions**:
1. Install language server options:
   - OmniSharp: `:MasonInstall omnisharp`
   - csharp-ls: `cargo install csharp-ls`
   - Roslyn: Download from Microsoft
2. Verify file type: `:set filetype?` (should be `cs`)
3. Check LSP status: `:LspInfo` or `:DotnetCoreLspStatus`
4. Restart LSP: `:LspRestart`

📖 **See [LSP_SETUP_GUIDE.md](LSP_SETUP_GUIDE.md) for detailed instructions**

#### Commands not found
**Error**: `E492: Not an editor command: DotnetCoreBuild`

**Solutions**:
1. Ensure plugin setup is called: `require("dotnet-core").setup()`
2. Check plugin loading: `:lua print(require('dotnet-core'))`
3. Verify you're in a .NET project directory

#### .NET CLI not found
**Error**: Health check shows dotnet CLI missing

**Solutions**:
1. Install .NET SDK from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download)
2. Restart terminal/Neovim after installation
3. Verify installation: `dotnet --version`

### Getting Help

1. **Run health check**: `:DotnetCoreHealth`
2. **Check messages**: `:messages`
3. **Create an issue** with:
   - Your OS and Neovim version
   - Output of `:DotnetCoreHealth`
   - Error messages
   - Your configuration

## 🐛 Debugging (Experimental)

**Current Status**: Basic debugging support is available but requires nvim-dap to be installed.

**Currently Available**:
- ✅ Basic breakpoint management
- ✅ Start/stop debugging sessions
- ✅ Basic DAP configuration for .NET Core

**Planned Features**:
- Step debugging (F10, F11, Shift+F11)
- Variable inspection windows
- Call stack navigation
- Debug console integration
- Conditional breakpoints
- Exception handling
- Multi-project debugging support

**Note**: This is experimental functionality. For full debugging support, ensure you have nvim-dap installed and configured.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Clone the repository
2. Install development dependencies
3. Run tests: `make test`
4. Submit PR with tests

### Roadmap

- [x] **Phase 1**: Foundation (LSP, dotnet CLI, basic commands) ✅
- [x] **Phase 2**: Enhanced navigation and refactoring ✅
- [x] **Phase 3**: Basic debugging integration (nvim-dap) 🟡 (experimental)
- [ ] **Phase 4**: Advanced project management
- [ ] **Phase 5**: Advanced debugging features (variable inspection, call stack)
- [ ] **Phase 6**: UI enhancements and themes
- [ ] **Phase 7**: Documentation and polish

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OmniSharp](https://github.com/OmniSharp/omnisharp-roslyn) - C# language server
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - LSP configuration
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) - Debug adapter protocol

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/anachary/dotnet-core.nvim/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/anachary/dotnet-core.nvim/discussions)
- 📖 **Documentation**: `:help dotnet-core`
- 🏥 **Health Check**: `:DotnetCoreHealth`

---

## 🧪 Testing the Plugin

To test the plugin after installation:

1. **Verify installation**:
   ```bash
   nvim -l ~/.local/share/nvim/lazy/dotnet-core.nvim/scripts/verify-install.lua
   ```

2. **Navigate to a .NET project**:
   ```bash
   cd your-dotnet-project
   nvim
   ```

3. **Run health check**:
   ```vim
   :DotnetCoreHealth
   ```

4. **Try basic commands**:
   ```vim
   :DotnetCoreBuild
   :DotnetCoreRun
   :DotnetCoreSolutionExplorer
   ```

## 📁 Project Structure

```
dotnet-core.nvim/
├── plugin/
│   └── dotnet-core.vim          # Plugin entry point
├── lua/dotnet-core/
│   ├── init.lua                 # Main plugin module
│   ├── config.lua               # Configuration management
│   ├── lsp.lua                  # LSP integration (OmniSharp)
│   ├── dotnet.lua               # Dotnet CLI integration
│   ├── commands.lua             # Command definitions
│   ├── keymaps.lua              # Keybinding setup
│   ├── health.lua               # Health check functionality
│   ├── project.lua              # Project management
│   ├── debug.lua                # Debugging support (experimental)
│   └── utils.lua                # Utility functions
├── doc/
│   └── dotnet-core.txt          # Neovim help documentation
├── LICENSE                      # MIT License
├── .gitignore                   # Git ignore file
└── README.md                    # This file
```

**Made with ❤️ for .NET developers who love Neovim**
