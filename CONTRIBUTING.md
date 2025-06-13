# Contributing to dotnet-core.nvim

Thank you for your interest in contributing to dotnet-core.nvim! This document provides guidelines for contributing to the project.

## 🚀 Getting Started

### Prerequisites

- Neovim >= 0.8.0
- .NET Core SDK
- Git
- Basic knowledge of Lua and .NET development

### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/dotnet-core.nvim.git
   cd dotnet-core.nvim
   ```
3. Create a new branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 How to Contribute

### Reporting Issues

- Use the [GitHub Issues](https://github.com/GustavEikaas/dotnet-core.nvim/issues) page
- Search existing issues before creating a new one
- Provide detailed information:
  - Neovim version
  - .NET SDK version
  - Operating system
  - Steps to reproduce
  - Expected vs actual behavior

### Suggesting Features

- Open a [GitHub Discussion](https://github.com/GustavEikaas/dotnet-core.nvim/discussions)
- Describe the feature and its use case
- Explain how it fits with the plugin's goals

### Code Contributions

1. **Follow the existing code style**:
   - Use 2 spaces for indentation
   - Follow Lua naming conventions
   - Add comments for complex logic
   - Keep functions focused and small

2. **Test your changes**:
   - Run `:DotnetCoreHealth` to ensure basic functionality
   - Test with different .NET project types
   - Verify LSP integration works correctly

3. **Update documentation**:
   - Update README.md if needed
   - Update help documentation in `doc/dotnet-core.txt`
   - Add docstrings to new functions

4. **Commit guidelines**:
   - Use conventional commit format: `type(scope): description`
   - Examples:
     - `feat(lsp): add go to implementation support`
     - `fix(dotnet): resolve build command error handling`
     - `docs(readme): update installation instructions`

## 🏗️ Project Structure

```
dotnet-core.nvim/
├── plugin/dotnet-core.vim       # Plugin entry point
├── lua/dotnet-core/
│   ├── init.lua                 # Main plugin module
│   ├── config.lua               # Configuration management
│   ├── lsp.lua                  # LSP integration
│   ├── dotnet.lua               # Dotnet CLI integration
│   ├── commands.lua             # Command definitions
│   ├── keymaps.lua              # Keybinding setup
│   ├── health.lua               # Health check functionality
│   ├── project.lua              # Project management
│   ├── debug.lua                # Debugging support
│   └── utils.lua                # Utility functions
└── doc/dotnet-core.txt          # Help documentation
```

## 🎯 Development Guidelines

### Code Style

- **Lua Style**: Follow standard Lua conventions
- **Error Handling**: Use pcall for potentially failing operations
- **Logging**: Use the utils.notify functions for user feedback
- **Configuration**: Make features configurable when appropriate

### Module Guidelines

- **init.lua**: Main plugin setup and coordination
- **config.lua**: All configuration management
- **lsp.lua**: LSP client integration and enhancements
- **dotnet.lua**: Dotnet CLI command integration
- **commands.lua**: User command definitions
- **keymaps.lua**: Keybinding management
- **health.lua**: Health check functionality
- **project.lua**: Project and solution management
- **debug.lua**: Debugging integration (nvim-dap)
- **utils.lua**: Shared utility functions

### Testing

- Test with various .NET project types (console, web, library)
- Test with both solution and standalone projects
- Verify LSP features work correctly
- Test on different operating systems if possible

## 🐛 Debugging

### Common Issues

1. **LSP not working**: Check OmniSharp installation and configuration
2. **Commands not found**: Verify plugin is properly loaded
3. **Build failures**: Check dotnet CLI availability and project structure

### Debug Tools

- `:DotnetCoreHealth` - Comprehensive health check
- `:checkhealth` - General Neovim health check
- `:LspInfo` - LSP client information
- `:messages` - View Neovim messages

## 📋 Pull Request Process

1. **Before submitting**:
   - Ensure your code follows the style guidelines
   - Test your changes thoroughly
   - Update documentation as needed
   - Rebase your branch on the latest main

2. **Pull request description**:
   - Clearly describe what your PR does
   - Reference any related issues
   - Include screenshots/demos if applicable
   - List any breaking changes

3. **Review process**:
   - Maintainers will review your PR
   - Address any feedback promptly
   - Be patient - reviews take time

## 🎖️ Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- GitHub contributors page

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## ❓ Questions?

- Open a [GitHub Discussion](https://github.com/GustavEikaas/dotnet-core.nvim/discussions)
- Check existing issues and discussions
- Read the documentation: `:help dotnet-core`

Thank you for contributing to dotnet-core.nvim! 🎉
