-- Bootstrap `packer.nvim`.
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path
  })
  vim.cmd 'packadd packer.nvim'
end


-- Install plugins.
local packer = require('packer')
packer.startup(function()
	use {'wbthomason/packer.nvim'}
	use {'nvim-treesitter/nvim-treesitter'}
	use {
      'lewis6991/gitsigns.nvim',
      requires = {'nvim-lua/plenary.nvim'}
  }
	use {'neovim/nvim-lspconfig'}
	use {'tpope/vim-surround'}
	use {'tpope/vim-repeat'}
	use {'tpope/vim-fugitive'}
  use {'tpope/vim-unimpaired'}
	use {'sheerun/vim-polyglot'}
	use {'itchyny/lightline.vim'}
	use {'preservim/nerdcommenter'}
	use {'preservim/vimux'}
	use {'alvan/vim-closetag'}
	use {'airblade/vim-rooter'}
	use {'vim-test/vim-test'}
	use {'morhetz/gruvbox'}
	use {
    'kkoomen/vim-doge', 
  run = function() fn["doge#install"]() end 
  }
	use {'rust-lang/rust.vim'}
	use {
		'nvim-telescope/telescope.nvim',
		requires = { { 'nvim-lua/plenary.nvim' } }
	}
  use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippets plugin
  use 'norcalli/nvim_utils' -- init.lua utils
  use 'folke/lua-dev.nvim'
  use 'mfussenegger/nvim-jdtls'
  use 'kabouzeid/nvim-lspinstall'
  use {'tzachar/cmp-tabnine', run='./install.sh', requires = 'hrsh7th/nvim-cmp'}
  use {'jiangmiao/auto-pairs'}

  packer.install()
  packer.compile()
end)

-- TabNine support.
local tabnine = require('cmp_tabnine.config')
tabnine:setup({
        max_lines = 1000;
        max_num_results = 20;
        sort = true;
	run_on_every_keystroke = true;
	snippet_placeholder = '..';
})

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = function(fallback)
      if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-n>', true, true, true), 'n')
      elseif luasnip.expand_or_jumpable() then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-expand-or-jump', true, true, true), '')
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-p>', true, true, true), 'n')
      elseif luasnip.jumpable(-1) then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-prev', true, true, true), '')
      else
        fallback()
      end
    end,
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'cmp_tabnine' }
  },
}

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

-- Lua development.
local function setup_servers()
  local lspinstall = require('lspinstall')
  lspinstall.setup()

  local lspconfig = require('lspconfig')
  local servers = lspinstall.installed_servers()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  for _, server in pairs(servers) do
    local opts = {
      on_attach = on_attach,
      flags = {
        debounce_text_changes = 150
      },
      capabilities = capabilities
    }

    if server == "lua" then
      local luadev = require("lua-dev").setup({lspconfig = opts})
      lspconfig[server].setup(luadev)
    else
      if server == "java" then
        local jdtls = vim.fn.stdpath("data").."/lspinstall/java/".."jdtls.sh"
        opts.cmd = {jdtls}
        --[[
           [opts.init_options = {
           [  settings = {
           [         ["java.format.settings.url"] = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
           [         ["java.format.settings.profile"] = "GoogleStyle",
           [         ["java.trace.server"] = "verbose",
           [         ["java.maven.downloadSources"] = true,
           [         ["java.import.maven.enabled"] = true,
           [         ["java.format.enabled"] = false
           [  }
           [}
           ]]
      end

      if server == "typescript" then
        opts.on_attach = function (client, bufnr)
          client.resolved_capabilities.document_formatting = false
          on_attach(client, bufnr)
        end
      end

      if server == "json" then
        capabilities.textDocument.completion.completionItem.snippetSupport = true

        opts.capabilities = capabilities
        opts.filetypes = {"json", "jsonc"}
        opts.settings = {
          json = {
            schemas = {
               {
                fileMatch = {"tsconfig.json"},
                url = 'http://json.schemastore.org/tsconfig.json'
              },
               {
                fileMatch = {".eslintrc.json", ".eslintrc"},
                url = 'http://json.schemastore.org/eslintrc.json'
              }
            }
          }
        }
      end

      if server == "efm" then
        -- Formatting & Linting.
        local eslint = {
          lintCommand = 'eslint_d -f unix --stdin --stdin-filename ${INPUT}',
          lintIgnoreExitCode = true,
          lintStdin = true,
          lintFormats = {"%f:%l:%c: %m"},
        }

        local prettier = {
            formatCommand = "npx prettier --stdin-filepath ${INPUT}",
            formatStdin = true
        }

        local luafmt = {
            formatCommand = "lua-format -i --no-keep-simple-function-one-line --no-break-after-operator --column-limit=150 --break-after-table-lb",
            formatStdin = true
        }

        local efm_settings = {
          lua = {luafmt},
          javascript = {eslint, prettier},
          javascriptreact = {eslint, prettier},
          typescript = {eslint, prettier},
          typescriptreact = {eslint, prettier},
          ["typescript.tsx"] = {eslint, prettier},
          ["javascript.jsx"] = {eslint, prettier}
        }

        local efmls = vim.fn.stdpath("data").."/lspinstall/efm/".."efm-langserver"

        opts.cmd = {
          efmls,
          "-logfile",
          "/tmp/efm.log"
        }

        opts.root_dir = lspconfig.util.root_pattern(".git", ".tsconfig", ".eslintrc")
        opts.init_options = {documentFormatting = true, codeAction = true}
        opts.filetypes = vim.tbl_keys(efm_settings)
        opts.settings = { languages  = efm_settings }
      end

      lspconfig[server].setup(opts)
    end
  end
end

setup_servers()

require('lspinstall').post_install_hook = function ()
  setup_servers() -- reload installed servers
  vim.cmd("bufdo e") -- this triggers the FileType autocmd that starts the server
end


-- Commands.
local cmd = vim.cmd
-- Global options.
local opt = vim.opt
-- Global 'let' options.
local g = vim.g
-- Window options.
local wo  = vim.wo
-- Api
local api = vim.api

-- Global let.
g.mapleader = ' '

-- Global Settings
wo.wrap = false
opt.relativenumber = true
opt.nu = true
opt.exrc = true
opt.guicursor = ""
opt.hidden = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.termguicolors = true
opt.scrolloff = 16
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.fileformat = "unix"
opt.background = "dark"
opt.undodir = vim.fn.stdpath('config')..'/undo'
opt.undofile = true

-- WSL copy/paste support.
opt.clipboard="unnamedplus"
g.clipboard = {
  name = "win32yank-wsl",
  copy = {
    ["+"] = "win32yank.exe -i --crlf",
    ["*"] = "win32yank.exe -i --crlf"
  },
  paste = {
    ["+"] = "win32yank.exe -o --crlf",
    ["*"] = "win32yank.exe -o --crlf"
  },
  cache_enable = 0,
}

-- Set colour scheme.
cmd([[colorscheme gruvbox]])

-- Window movement (LDUR).
vim.api.nvim_set_keymap('n', '<leader>h', ':wincmd h<CR>', {silent=true, noremap=true})
vim.api.nvim_set_keymap('n', '<leader>j', ':wincmd j<CR>', {silent=true, noremap=true})
vim.api.nvim_set_keymap('n', '<leader>k', ':wincmd k<CR>', {silent=true, noremap=true})
vim.api.nvim_set_keymap('n', '<leader>l', ':wincmd l<CR>', {silent=true, noremap=true})

-- Escape
api.nvim_set_keymap('i', 'jj', '<ESC>', {noremap=true, silent=true})

-- Telescope bindings.
api.nvim_set_keymap("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", {noremap=true, silent=true})
api.nvim_set_keymap("n", "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<cr>", {noremap=true, silent=true})
api.nvim_set_keymap("n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<cr>", {noremap=true, silent=true})
api.nvim_set_keymap("n", "<leader>fh", "<cmd>lua require('telescope.builtin').buffers()<cr>", {noremap=true, silent=true})

-- Augroups.
require('nvim_utils')

local autocmds = {
  toggle_hi = {
    { "InsertEnter", "*", "setlocal nohlsearch"}
  },
  autoFormat = {
    {"BufWritePre", "*", "lua vim.lsp.buf.formatting({}, 100)"}
  }
}

nvim_create_augroups(autocmds)
