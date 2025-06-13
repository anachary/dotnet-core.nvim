" dotnet-core.vim - Neovim plugin for .NET Core development
" Maintainer: Augment Agent
" Version: 1.0.0

if exists('g:loaded_dotnet_core')
  finish
endif
let g:loaded_dotnet_core = 1

" Check if Neovim version is compatible
if !has('nvim-0.8.0')
  echohl ErrorMsg
  echom 'dotnet-core.nvim requires Neovim 0.8.0 or later'
  echohl None
  finish
endif

" Initialize the plugin
lua require('dotnet-core').setup()

" Define plugin commands
command! -nargs=0 DotnetCoreSetup lua require('dotnet-core').setup()
command! -nargs=0 DotnetCoreHealth lua require('dotnet-core.health').check()
command! -nargs=0 DotnetCoreBuild lua require('dotnet-core.dotnet').build()
command! -nargs=0 DotnetCoreRun lua require('dotnet-core.dotnet').run()
command! -nargs=0 DotnetCoreTest lua require('dotnet-core.dotnet').test()
command! -nargs=0 DotnetCoreRestore lua require('dotnet-core.dotnet').restore()
command! -nargs=0 DotnetCoreClean lua require('dotnet-core.dotnet').clean()

" LSP and navigation commands
command! -nargs=0 DotnetCoreFindReferences lua require('dotnet-core.lsp').find_references()
command! -nargs=0 DotnetCoreGoToImplementation lua require('dotnet-core.lsp').go_to_implementation()
command! -nargs=0 DotnetCoreRename lua require('dotnet-core.lsp').rename()
command! -nargs=0 DotnetCoreCodeAction lua require('dotnet-core.lsp').code_action()

" Project management commands
command! -nargs=0 DotnetCoreSolutionExplorer lua require('dotnet-core.project').solution_explorer()
command! -nargs=0 DotnetCoreProjectStructure lua require('dotnet-core.project').show_structure()
