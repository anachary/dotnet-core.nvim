-- dotnet-core/lsp.lua - LSP integration for OmniSharp/Roslyn

local M = {}
local utils = require('dotnet-core.utils')
local config = require('dotnet-core.config')

-- LSP client state
local lsp_client_id = nil
local lsp_attached_buffers = {}

-- Setup LSP configuration
function M.setup(lsp_config)
  -- Configure OmniSharp LSP
  local lspconfig = require('lspconfig')
  
  -- Get the LSP configuration from our config module
  local omnisharp_config = config.get_lsp_config()
  
  -- Enhanced capabilities for better .NET Core support
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" }
  }
  
  -- Add custom handlers for better .NET Core experience
  omnisharp_config.handlers = {
    ["textDocument/definition"] = M.enhanced_go_to_definition,
    ["textDocument/references"] = M.enhanced_find_references,
    ["textDocument/implementation"] = M.enhanced_go_to_implementation,
    ["textDocument/codeAction"] = M.enhanced_code_action,
  }
  
  omnisharp_config.capabilities = capabilities
  omnisharp_config.on_attach = M.on_attach
  
  -- Setup OmniSharp
  lspconfig.omnisharp.setup(omnisharp_config)
  
  utils.info("LSP configuration loaded for OmniSharp")
end

-- Enhanced on_attach function for .NET Core specific features
function M.on_attach(client, bufnr)
  lsp_client_id = client.id
  lsp_attached_buffers[bufnr] = true
  
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  
  -- Buffer-local mappings for LSP functions
  local opts = { noremap = true, silent = true, buffer = bufnr }
  
  -- Navigation
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gi', M.go_to_implementation, opts)
  vim.keymap.set('n', 'gr', M.find_references, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  
  -- Code actions and refactoring
  vim.keymap.set('n', '<leader>ca', M.code_action, opts)
  vim.keymap.set('n', '<leader>rn', M.rename, opts)
  vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
  
  -- Diagnostics
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
  
  utils.info("LSP attached to buffer " .. bufnr)
end

-- Enhanced go to definition with .NET Core specific handling
function M.enhanced_go_to_definition(err, result, ctx, config)
  if err then
    utils.error("Go to definition failed: " .. err.message)
    return
  end
  
  if not result or vim.tbl_isempty(result) then
    utils.warn("No definition found")
    return
  end
  
  -- Handle multiple definitions (e.g., partial classes)
  if #result > 1 then
    M.show_definition_picker(result)
  else
    vim.lsp.util.jump_to_location(result[1], 'utf-8')
  end
end

-- Enhanced find references with better UI
function M.enhanced_find_references(err, result, ctx, config)
  if err then
    utils.error("Find references failed: " .. err.message)
    return
  end
  
  if not result or vim.tbl_isempty(result) then
    utils.warn("No references found")
    return
  end
  
  -- Use Telescope if available, otherwise use quickfix
  local has_telescope, telescope = pcall(require, 'telescope.builtin')
  if has_telescope then
    telescope.lsp_references()
  else
    vim.lsp.util.set_qflist(vim.lsp.util.locations_to_items(result, 'utf-8'))
    vim.cmd('copen')
  end
  
  utils.info(string.format("Found %d references", #result))
end

-- Enhanced go to implementation
function M.enhanced_go_to_implementation(err, result, ctx, config)
  if err then
    utils.error("Go to implementation failed: " .. err.message)
    return
  end
  
  if not result or vim.tbl_isempty(result) then
    utils.warn("No implementation found")
    return
  end
  
  -- Handle multiple implementations
  if #result > 1 then
    M.show_implementation_picker(result)
  else
    vim.lsp.util.jump_to_location(result[1], 'utf-8')
  end
end

-- Enhanced code action with .NET Core specific actions
function M.enhanced_code_action(err, result, ctx, config)
  if err then
    utils.error("Code action failed: " .. err.message)
    return
  end
  
  if not result or vim.tbl_isempty(result) then
    utils.warn("No code actions available")
    return
  end
  
  -- Filter and prioritize .NET Core specific actions
  local filtered_actions = M.filter_dotnet_actions(result)
  
  -- Use Telescope if available for better UI
  local has_telescope, telescope = pcall(require, 'telescope.builtin')
  if has_telescope then
    telescope.lsp_code_actions()
  else
    vim.lsp.buf.code_action()
  end
end

-- Filter code actions to prioritize .NET Core specific ones
function M.filter_dotnet_actions(actions)
  local dotnet_actions = {}
  local other_actions = {}
  
  for _, action in ipairs(actions) do
    local title = action.title or ""
    if title:match("using") or title:match("namespace") or title:match("class") or 
       title:match("interface") or title:match("method") or title:match("property") then
      table.insert(dotnet_actions, action)
    else
      table.insert(other_actions, action)
    end
  end
  
  -- Return .NET actions first, then others
  vim.list_extend(dotnet_actions, other_actions)
  return dotnet_actions
end

-- Show definition picker for multiple definitions
function M.show_definition_picker(definitions)
  local items = {}
  for i, def in ipairs(definitions) do
    local uri = def.uri or def.targetUri
    local range = def.range or def.targetSelectionRange
    local filename = vim.uri_to_fname(uri)
    local line = range.start.line + 1
    
    table.insert(items, {
      text = string.format("%s:%d", vim.fn.fnamemodify(filename, ":t"), line),
      filename = filename,
      lnum = line,
      col = range.start.character + 1,
    })
  end
  
  vim.ui.select(items, {
    prompt = "Select definition:",
    format_item = function(item) return item.text end,
  }, function(choice)
    if choice then
      vim.cmd(string.format("edit +%d %s", choice.lnum, choice.filename))
    end
  end)
end

-- Show implementation picker for multiple implementations
function M.show_implementation_picker(implementations)
  M.show_definition_picker(implementations) -- Same logic for now
end

-- Public API functions
function M.find_references()
  if not M.is_lsp_attached() then
    utils.warn("LSP not attached to current buffer")
    return
  end
  
  vim.lsp.buf.references()
end

function M.go_to_implementation()
  if not M.is_lsp_attached() then
    utils.warn("LSP not attached to current buffer")
    return
  end
  
  vim.lsp.buf.implementation()
end

function M.rename()
  if not M.is_lsp_attached() then
    utils.warn("LSP not attached to current buffer")
    return
  end
  
  vim.lsp.buf.rename()
end

function M.code_action()
  if not M.is_lsp_attached() then
    utils.warn("LSP not attached to current buffer")
    return
  end
  
  vim.lsp.buf.code_action()
end

-- Attach LSP to current buffer if it's a .NET file
function M.attach_to_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  
  if not utils.is_dotnet_file(bufnr) then
    return
  end
  
  if lsp_attached_buffers[bufnr] then
    return -- Already attached
  end
  
  -- Trigger LSP attachment by setting filetype
  vim.api.nvim_buf_set_option(bufnr, 'filetype', vim.api.nvim_buf_get_option(bufnr, 'filetype'))
end

-- Check if LSP is attached to current buffer
function M.is_lsp_attached()
  local bufnr = vim.api.nvim_get_current_buf()
  return lsp_attached_buffers[bufnr] == true
end

-- Get LSP client info
function M.get_client_info()
  if lsp_client_id then
    return vim.lsp.get_client_by_id(lsp_client_id)
  end
  return nil
end

return M
