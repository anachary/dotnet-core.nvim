# Changelog

All notable changes to dotnet-core.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced debugging support with nvim-dap integration
- Navigation history for code browsing
- Extract method/variable refactoring capabilities
- Change signature refactoring
- Refactoring preview system

### Changed
- Improved error handling and user feedback
- Enhanced UI components and themes

### Fixed
- Various bug fixes and performance improvements

## [1.0.0] - 2024-01-XX

### Added
- Initial release of dotnet-core.nvim
- LSP integration with OmniSharp/Roslyn for C# language support
- Comprehensive dotnet CLI integration (build, run, test, restore, clean)
- Solution explorer with tree view navigation
- Project management and structure visualization
- Enhanced code navigation (go to definition, find references, go to implementation)
- Rename symbol functionality with cross-project support
- Code actions and quick fixes
- NuGet package management (add/remove packages)
- Project template creation support
- Comprehensive health check system
- Customizable keybinding system with sensible defaults
- Floating window UI components
- Auto-detection of .NET solutions and projects
- Support for multiple .NET project types (console, web, library, test, etc.)
- Configuration system with extensive customization options
- Complete documentation and help system

### Dependencies
- Neovim >= 0.8.0
- nvim-lspconfig (required)
- telescope.nvim (optional, for enhanced UI)
- nvim-dap (optional, for debugging support)

### Supported Project Types
- Console applications
- Class libraries
- ASP.NET Core web applications
- ASP.NET Core Web APIs
- ASP.NET Core MVC applications
- Blazor Server applications
- Blazor WebAssembly applications
- Worker services
- Windows Forms applications
- WPF applications
- xUnit test projects
- NUnit test projects
- MSTest test projects

### Commands Added
- `:DotnetCoreSetup` - Initialize/reinitialize the plugin
- `:DotnetCoreHealth` - Comprehensive health check
- `:DotnetCoreBuild` - Build project/solution
- `:DotnetCoreRun` - Run project
- `:DotnetCoreTest` - Run tests
- `:DotnetCoreRestore` - Restore NuGet packages
- `:DotnetCoreClean` - Clean build artifacts
- `:DotnetCoreFindReferences` - Find all references to symbol
- `:DotnetCoreGoToImplementation` - Go to implementation
- `:DotnetCoreRename` - Rename symbol
- `:DotnetCoreCodeAction` - Show available code actions
- `:DotnetCoreSolutionExplorer` - Open solution explorer
- `:DotnetCoreProjectStructure` - Show project structure
- `:DotnetCoreNewProject` - Create new project
- `:DotnetCoreNewSolution` - Create new solution
- `:DotnetCoreAddPackage` - Add NuGet package
- `:DotnetCoreRemovePackage` - Remove NuGet package

### Keybindings Added
- `<leader>d` prefix for all dotnet commands (configurable)
- Build and run shortcuts (`<leader>db`, `<leader>dr`, etc.)
- Code navigation shortcuts (`<leader>dfr`, `<leader>dgi`, etc.)
- Project management shortcuts (`<leader>dse`, `<leader>dps`, etc.)
- Buffer-local shortcuts for .NET files (`gd`, `gr`, `gi`, `<F2>`, etc.)

### Configuration Options
- LSP configuration for OmniSharp
- Dotnet CLI behavior settings
- UI customization (borders, icons, transparency)
- Keybinding customization
- Auto-features (auto-restore, build-on-save, test-on-save)
- Project management settings

## [0.1.0] - Development

### Added
- Initial development and prototyping
- Core plugin architecture
- Basic LSP integration
- Fundamental dotnet CLI commands
