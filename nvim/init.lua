-- Bootstrap `packer.nvim`.
local fn = vim.fn
local root_dir = fn.stdpath('data')
local install_path = root_dir .. '/site/pack/packer/start/packer.nvim'
local lsp_servers_dir = root_dir .. '/lsp_servers'

if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({
        'git', 'clone', '--depth', '1',
        'https://github.com/wbthomason/packer.nvim', install_path
    })
    vim.cmd 'packadd packer.nvim'
end

-- Install plugins.
local packer = require('packer')
packer.startup(function()
    use {'wbthomason/packer.nvim'}
    use {'nvim-treesitter/nvim-treesitter'}
    use {'sheerun/vim-polyglot'}
    use {'neovim/nvim-lspconfig'}
    use {'lewis6991/gitsigns.nvim', requires = {'nvim-lua/plenary.nvim'}}
    use {'tpope/vim-surround'}
    use {'tpope/vim-repeat'}
    use {'tpope/vim-fugitive'}
    use {'itchyny/lightline.vim'}
    use {'preservim/nerdcommenter'}
    use {'preservim/vimux'}
    use {'alvan/vim-closetag'}
    use {'airblade/vim-rooter'}
    use {'morhetz/gruvbox'}
    use {'kkoomen/vim-doge', run = function() fn["doge#install"]() end}
    use {'rust-lang/rust.vim'}
    use {
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/plenary.nvim'}}
    }
    use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make'}
    use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
    use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
    use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
    use 'L3MON4D3/LuaSnip' -- Snippets plugin
    use 'norcalli/nvim_utils' -- init.lua utils
    use 'folke/lua-dev.nvim'
    use 'williamboman/nvim-lsp-installer'
    use {
        'tzachar/cmp-tabnine',
        run = './install.sh',
        requires = 'hrsh7th/nvim-cmp'
    }
    use {'windwp/nvim-autopairs'}
    use {
        'rcarriga/vim-ultest',
        requires = {"vim-test/vim-test"},
        run = ":UpdateRemotePlugins"
    }
    use {'lervag/vimtex', ft = 'tex', opt = true}
end)

require('telescope').load_extension('fzf')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    local function buf_set_option(...)
        vim.api.nvim_buf_set_option(bufnr, ...)
    end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = {noremap = true, silent = true}

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>',
                   opts)
    buf_set_keymap('n', '<space>wa',
                   '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr',
                   '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl',
                   '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>',
                   opts)
    buf_set_keymap('n', '<space>D',
                   '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>',
                   opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e',
                   '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>',
                   opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>',
                   opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>',
                   opts)
    buf_set_keymap('n', '<space>q',
                   '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>',
                   opts)
end

-- LSP set up.
local lsp_installer = require('nvim-lsp-installer')
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp
                                                                     .protocol
                                                                     .make_client_capabilities())

lsp_installer.on_server_ready(function(server)
    local opts = {
        on_attach = on_attach,
        flags = {debounce_text_changes = 150},
        capabilities = capabilities
    }
    if server.name == "sumneko_lua" then
        local luadev = require("lua-dev").setup({lspconfig = opts})
        server:setup(luadev)
    else
        local java_cmd = require("utils.java_utils")
        if server.name == "jdtls" then
            opts.cmd = java_cmd(lsp_servers_dir .. "/jdtls")
            opts.init_options = {
                settings = {
                    ["java.format.settings.url"] = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
                    ["java.format.settings.profile"] = "GoogleStyle",
                    ["java.format.enabled"] = true,
                    ["java.trace.server"] = "verbose",
                    ["java.maven.downloadSources"] = true,
                    ["java.import.maven.enabled"] = true
                }
            }
        end

        if server.name == "tsserver" then
            opts.on_attach = function(client, bufnr)
                client.resolved_capabilities.document_formatting = false
                on_attach(client, bufnr)
            end
        end

        if server.name == "yamlls" then
            opts.filetypes = {"yaml"}
            opts.settings = {
                yaml = {
                    schemas = {
                        'https://bitbucket.org/atlassianlabs/atlascode/raw/main/resources/schemas/pipelines-schema.json'
                    }
                }
            }
        end

        if server.name == "jsonls" then
            opts.on_attach = function(client, bufnr)
                client.resolved_capabilities.document_formatting = false
                on_attach(client, bufnr)
            end

            capabilities.textDocument.completion.completionItem.snippetSupport =
                true

            opts.capabilities = capabilities
            opts.filetypes = {"json", "jsonc"}
            opts.settings = {
                json = {
                    format = {enable = false},
                    schemas = {
                        {
                            fileMatch = {"tsconfig.json"},
                            url = 'http://json.schemastore.org/tsconfig.json'
                        }, {
                            fileMatch = {".eslintrc.json", ".eslintrc"},
                            url = 'http://json.schemastore.org/eslintrc.json'
                        }
                    }
                }
            }
        end

        if server.name == "pyright" then
            opts.settings = {python = {pythonPath = "/usr/bin/python3.9"}}
        end

        if server.name == "efm" then
            -- Formatting & Linting.
            local eslint = {
                lintCommand = 'eslint_d -f unix --stdin --stdin-filename ${INPUT}',
                lintIgnoreExitCode = true,
                lintStdin = true,
                lintFormats = {"%f:%l:%c: %m"}
            }

            local prettier = {
                formatCommand = "npx prettier --stdin-filepath ${INPUT}",
                formatStdin = true
            }

            local luafmt = {formatCommand = "lua-format -i", formatStdin = true}

            local black = {
                formatCommand = "python3.9 -m black --quiet -",
                formatStdin = true
            }

            local yamllint = {
                lintCommand = "yamllint -f parsable -",
                lintStdin = true
            }

            local efm_settings = {
                yaml = {yamllint, prettier},
                json = {prettier},
                python = {black},
                lua = {luafmt},
                javascript = {eslint, prettier},
                javascriptreact = {eslint, prettier},
                typescript = {eslint, prettier},
                typescriptreact = {eslint, prettier}
            }

            local efmls = lsp_servers_dir .. "/efm/" .. "efm-langserver"

            opts.cmd = {efmls, "-logfile", "/tmp/efm.log"}

            opts.root_dir = function(filename)
                return lspconfig.util.root_pattern(".git", ".tsconfig",
                                                   ".eslintrc")(filename) or
                           vim.fn.getcwd()
            end

            opts.init_options = {documentFormatting = true, codeAction = true}
            opts.filetypes = vim.tbl_keys(efm_settings)
            opts.settings = {languages = efm_settings}
        end
        server:setup(opts)
        vim.cmd [[ do User LspAttachBuffers ]]
    end
end)

lspconfig.perlls.setup {
    on_attach = on_attach,
    flags = {debounce_text_changes = 150},
    capabilities = capabilities
}

-- TabNine support.
local tabnine = require('cmp_tabnine.config')
tabnine:setup({
    max_lines = 1000,
    max_num_results = 20,
    sort = true,
    run_on_every_keystroke = true,
    snippet_placeholder = '..'
})

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup

local cmp = require 'cmp'
cmp.setup {
    snippet = {
        expand = function(args) require('luasnip').lsp_expand(args.body) end
    },
    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<Tab>'] = function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end,
        ['<S-Tab>'] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end
    },
    completion = {completeopt = 'menu,menuone,noinsert'},
    sources = {{name = 'nvim_lsp'}, {name = 'luasnip'}, {name = 'cmp_tabnine'}}
}

-- you need setup cmp first put this after cmp.setup()
require('nvim-autopairs').setup {}
require("nvim-autopairs.completion.cmp").setup({
    map_cr = true, --  map <CR> on insert mode
    map_complete = true, -- it will auto insert `(` (map_char) after select function or method item
    auto_select = true, -- automatically select the first item
    insert = false, -- use insert confirm behavior instead of replace
    map_char = { -- modifies the function or method delimiter by filetypes
        all = '(',
        tex = '{'
    }
})

-- Commands.
local cmd = vim.cmd
-- Global options.
local opt = vim.opt
-- Global 'let' options.
local g = vim.g
-- Window options.
local wo = vim.wo
-- Api
local api = vim.api

-- Global let.
g.mapleader = ' '
g.python3_host_prog = "/usr/bin/python3.9"
g["test#strategy"] = "vimux"
g["test#javascript#runner"] = "jest"
g["test#javascript#jest#options"] = "-c"
g["tex_flavor"] = "latex"
g['vimtex_compiler_latexmk'] = {
    options = {
        '-pdf', '-pdflatex="xelatex --shell-escape %O %S"', '-verbose',
        '-file-line-error', '-synctex=1', '-interaction=nonstopmode'
    }
}

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
opt.undodir = vim.fn.stdpath('config') .. '/undo'
opt.undofile = true

-- WSL copy/paste support.
opt.clipboard = "unnamedplus"
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
    cache_enable = 0
}

-- Set colour scheme.
cmd([[colorscheme gruvbox]])

-- Window movement (LDUR).
vim.api.nvim_set_keymap('n', '<leader>h', ':wincmd h<CR>',
                        {silent = true, noremap = true})
vim.api.nvim_set_keymap('n', '<leader>j', ':wincmd j<CR>',
                        {silent = true, noremap = true})
vim.api.nvim_set_keymap('n', '<leader>k', ':wincmd k<CR>',
                        {silent = true, noremap = true})
vim.api.nvim_set_keymap('n', '<leader>l', ':wincmd l<CR>',
                        {silent = true, noremap = true})

-- Escape
api.nvim_set_keymap('i', 'jj', '<ESC>', {noremap = true, silent = true})

-- Telescope bindings.
api.nvim_set_keymap("n", "<leader>ff",
                    "<cmd>lua require('telescope.builtin').find_files()<cr>",
                    {noremap = true, silent = true})
api.nvim_set_keymap("n", "<leader>fg",
                    "<cmd>lua require('telescope.builtin').live_grep()<cr>",
                    {noremap = true, silent = true})
api.nvim_set_keymap("n", "<leader>fb",
                    "<cmd>lua require('telescope.builtin').buffers()<cr>",
                    {noremap = true, silent = true})
api.nvim_set_keymap("n", "<leader>fh",
                    "<cmd>lua require('telescope.builtin').buffers()<cr>",
                    {noremap = true, silent = true})

-- Augroups.
require('nvim_utils')

local autocmds = {
    toggle_hi = {{"InsertEnter", "*", "setlocal nohlsearch"}},
    autoFormat = {{"BufWritePre", "*", "lua vim.lsp.buf.formatting({}, 100)"}}
}

nvim_create_augroups(autocmds)
