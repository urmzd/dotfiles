local opt = vim.opt
-- Global 'let' Options
local g = vim.g
-- Window Options
local wo = vim.wo

local colorscheme = "ayu"

vim.cmd('colorscheme ' .. colorscheme)

-- Global let.
g.mapleader = ' '
g["test#strategy"] = "vimux"
g["doge_doc_standard_python"] = "google"

g["test#javascript#runner"] = "jest"
g["test#javascript#jest#options"] = "-c"

g["test#rust#cargotest#executable"] = "cargo test"
g["test#rust#cargotest#options"] = "-- --show-output"

g.tex_flavor = "latex"
g.vimtex_compiler_latexmk = {
  options = {
    '-pdf', '-pdflatex="xelatex --shell-escape %O %S"', '-verbose',
    '-file-line-error', '-synctex=1', '-interaction=nonstopmode'
  }
}

g.lightline = { colorscheme = colorscheme }

-- Global Settings
wo.wrap = false
opt.clipboard = "unnamedplus"
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
opt.nrformats = "alpha"
