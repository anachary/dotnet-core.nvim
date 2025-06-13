# 🔧 LSP Setup Guide for dotnet-core.nvim

## ❌ Problem: "gd", "gi", "gr" not working?

If go to definition, implementation, and references are not working, you need to install a **C# Language Server**.

## 🚀 Quick Fix

### Option 1: OmniSharp (Recommended for beginners)
```vim
:MasonInstall omnisharp
```

### Option 2: csharp-ls (Lightweight)
```bash
cargo install csharp-ls
```

### Option 3: Roslyn (Microsoft Official)
```bash
# Download from: https://github.com/dotnet/roslyn/releases
# Or install via your package manager
```

## 🔍 Diagnosis Commands

### Check what's wrong:
```vim
:DotnetCoreHealth
```

### Check LSP status:
```vim
:DotnetCoreLspStatus
```

### Check LSP info (in a .cs file):
```vim
:LspInfo
```

## ✅ Verification

After installing a language server:

1. **Restart Neovim**
2. **Open a .cs file**
3. **Test the keybindings:**
   - `gd` - Go to definition
   - `gi` - Go to implementation  
   - `gr` - Find references
   - `K` - Hover information
   - `F12` - Go to definition (VS style)
   - `Ctrl+F12` - Go to implementation (VS style)
   - `Shift+F12` - Find references (VS style)

## 🎯 Expected Output

When working correctly, you should see:
```
:DotnetCoreLspStatus
✅ LSP clients attached:
   • omnisharp (or csharp_ls, or roslyn)
     - Definition: ✅
     - Implementation: ✅
     - References: ✅
     - Hover: ✅
     - Rename: ✅
```

## 🐛 Still Not Working?

1. **Check .NET SDK is installed:**
   ```bash
   dotnet --version
   ```

2. **Check language server is in PATH:**
   ```bash
   # For OmniSharp
   omnisharp --version
   
   # For csharp-ls
   csharp-ls --version
   ```

3. **Check Neovim LSP logs:**
   ```vim
   :lua vim.cmd('e ' .. vim.lsp.get_log_path())
   ```

4. **Try manual LSP start:**
   ```vim
   :LspStart omnisharp
   ```

## 📚 Language Server Comparison

| Server | Speed | Features | Installation |
|--------|-------|----------|--------------|
| **OmniSharp** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | `:MasonInstall omnisharp` |
| **csharp-ls** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | `cargo install csharp-ls` |
| **Roslyn** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Manual download |

## 🎉 Success!

Once working, you'll have:
- **Visual Studio-style keybindings** (F12, Ctrl+F12, etc.)
- **Traditional Neovim keybindings** (gd, gi, gr, K)
- **Full IntelliSense** support
- **Code actions** and **refactoring**
- **Real-time diagnostics**

Happy coding! 🚀
