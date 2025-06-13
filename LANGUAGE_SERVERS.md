# C# Language Server Options

The dotnet-core.nvim plugin now supports multiple C# language servers! Here are your options:

## 🚀 **Recommended: Roslyn Language Server (Microsoft Official)**

### ✅ **Advantages:**
- ✅ **Fastest startup** (2-3 seconds vs 10-15 for OmniSharp)
- ✅ **Most reliable** (official Microsoft support)
- ✅ **Better performance** (lower memory usage)
- ✅ **Latest features** (always up-to-date)

### **Installation:**
```bash
# Install via .NET tool
dotnet tool install -g Microsoft.CodeAnalysis.LanguageServer

# Or via Mason (if available)
:MasonInstall roslyn
```

## 🪶 **Lightweight: csharp-ls**

### ✅ **Advantages:**
- ✅ **Very fast startup** (1-2 seconds)
- ✅ **Low memory usage**
- ✅ **Simple and reliable**
- ✅ **No dependencies**

### **Installation:**
```bash
# Install via cargo
cargo install csharp-ls

# Or download from releases
# https://github.com/razzmatazz/csharp-language-server/releases
```

## 🔧 **Traditional: OmniSharp**

### ⚠️ **Disadvantages:**
- ❌ **Slow startup** (10-15 seconds)
- ❌ **High memory usage**
- ❌ **Complex setup**
- ❌ **Frequent issues**

### **Installation:**
```bash
# Via Mason
:MasonInstall omnisharp

# Or manual download
# https://github.com/OmniSharp/omnisharp-roslyn/releases
```

## 🎯 **Configuration Examples**

### **Auto-detect (Recommended):**
```lua
require("dotnet-core").setup({
  lsp = {
    server_type = "auto", -- Will use best available server
  },
})
```

### **Force Roslyn:**
```lua
require("dotnet-core").setup({
  lsp = {
    server_type = "roslyn",
  },
})
```

### **Force csharp-ls:**
```lua
require("dotnet-core").setup({
  lsp = {
    server_type = "csharp_ls",
  },
})
```

### **Force OmniSharp:**
```lua
require("dotnet-core").setup({
  lsp = {
    server_type = "omnisharp",
  },
})
```

## 🏆 **Recommendation**

**For best experience:** Use `server_type = "auto"` and install Roslyn:

```bash
dotnet tool install -g Microsoft.CodeAnalysis.LanguageServer
```

The plugin will automatically detect and use the best available language server!

## 🔍 **Check What's Available**

Run `:DotnetCoreHealth` or `<leader>h` to see which language servers are detected on your system.
