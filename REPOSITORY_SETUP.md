# Repository Setup Guide

This document provides instructions for setting up the dotnet-core.nvim repository for distribution to the Neovim community.

## 📁 Repository Structure

The repository is now organized as a clean, production-ready Neovim plugin:

```
dotnet-core.nvim/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md        # Bug report template
│   │   └── feature_request.md   # Feature request template
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI/CD
├── doc/
│   └── dotnet-core.txt          # Neovim help documentation
├── lua/dotnet-core/
│   ├── init.lua                 # Main plugin module
│   ├── config.lua               # Configuration management
│   ├── lsp.lua                  # LSP integration (OmniSharp)
│   ├── dotnet.lua               # Dotnet CLI integration
│   ├── commands.lua             # Command definitions
│   ├── keymaps.lua              # Keybinding setup
│   ├── health.lua               # Health check functionality
│   ├── project.lua              # Project management
│   ├── debug.lua                # Debugging support (placeholder)
│   └── utils.lua                # Utility functions
├── plugin/
│   └── dotnet-core.vim          # Plugin entry point
├── scripts/
│   ├── verify-install.lua       # Installation verification
│   ├── setup-git.sh             # Git setup script (Unix)
│   └── setup-git.bat            # Git setup script (Windows)
├── .gitignore                   # Git ignore file
├── CHANGELOG.md                 # Version history
├── CONTRIBUTING.md              # Contribution guidelines
├── LICENSE                      # MIT License
├── plugin.json                  # Plugin metadata
├── README.md                    # Main documentation
└── REPOSITORY_SETUP.md          # This file
```

## 🚀 Quick Setup

### 1. Initialize Git Repository

**Unix/Linux/macOS:**
```bash
chmod +x scripts/setup-git.sh
./scripts/setup-git.sh
```

**Windows:**
```cmd
scripts\setup-git.bat
```

### 2. Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository named `dotnet-core.nvim`
2. Don't initialize with README, .gitignore, or license (we already have these)
3. Copy the repository URL

### 3. Push to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/dotnet-core.nvim.git
git branch -M main
git push -u origin main
```

### 4. Update Repository URLs

Update the following files with your actual GitHub username:

- `README.md` - Update installation examples and links
- `CONTRIBUTING.md` - Update issue and discussion links
- `plugin.json` - Update repository URL
- `.github/ISSUE_TEMPLATE/*.md` - Update any hardcoded URLs

## 📦 Package Manager Distribution

### Lazy.nvim
Users can install with:
```lua
{
  "YOUR_USERNAME/dotnet-core.nvim",
  dependencies = {
    "neovim/nvim-lspconfig",
    "nvim-telescope/telescope.nvim", -- Optional
    "mfussenegger/nvim-dap",        -- Optional
  },
  config = function()
    require("dotnet-core").setup()
  end,
}
```

### Packer.nvim
```lua
use {
  "YOUR_USERNAME/dotnet-core.nvim",
  requires = {
    "neovim/nvim-lspconfig",
    "nvim-telescope/telescope.nvim", -- Optional
    "mfussenegger/nvim-dap",        -- Optional
  },
  config = function()
    require("dotnet-core").setup()
  end
}
```

### vim-plug
```vim
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-telescope/telescope.nvim'  " Optional
Plug 'mfussenegger/nvim-dap'          " Optional
Plug 'YOUR_USERNAME/dotnet-core.nvim'
```

## 🏷️ Versioning and Releases

### Creating Releases

1. Update `CHANGELOG.md` with new version information
2. Update version in `plugin.json`
3. Create a git tag:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
4. Create a GitHub release from the tag

### Semantic Versioning

Follow [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH`
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes (backward compatible)

## 🔧 Maintenance

### Regular Tasks

1. **Monitor Issues**: Respond to bug reports and feature requests
2. **Update Dependencies**: Keep LSP and other integrations current
3. **Documentation**: Keep README and help docs updated
4. **Testing**: Verify compatibility with new Neovim versions
5. **Community**: Engage with users and contributors

### CI/CD Pipeline

The included GitHub Actions workflow:
- Runs on push/PR to main branch
- Tests on multiple OS (Ubuntu, Windows, macOS)
- Tests with multiple Neovim versions
- Lints Lua code with luacheck
- Validates documentation

## 📋 Community Guidelines

### Issue Management

- Use provided templates for bugs and features
- Label issues appropriately
- Respond promptly to community feedback
- Close resolved issues with clear explanations

### Pull Request Process

1. Contributors fork the repository
2. Create feature branches
3. Submit PRs with clear descriptions
4. Maintainers review and provide feedback
5. Merge after approval and testing

### Documentation

- Keep README.md comprehensive and up-to-date
- Maintain help documentation in `doc/dotnet-core.txt`
- Update CHANGELOG.md for all releases
- Provide clear examples and use cases

## 🎯 Success Metrics

Track plugin adoption through:
- GitHub stars and forks
- Issue reports and feature requests
- Community discussions
- Download statistics (if available)

## 📞 Support Channels

- **Issues**: Bug reports and technical problems
- **Discussions**: Feature requests and general questions
- **Documentation**: `:help dotnet-core` in Neovim

## 🎉 Ready for Distribution!

The repository is now ready for:
- ✅ Community distribution
- ✅ Package manager inclusion
- ✅ GitHub repository hosting
- ✅ Issue tracking and management
- ✅ Continuous integration
- ✅ Community contributions

Simply follow the setup steps above and your plugin will be available to the entire Neovim community!
