local opt = vim.opt
-- Global 'let' Options
local g = vim.g
-- Window Options
local wo = vim.wo


-- Global let.
g.mapleader = ' '
g["doge_doc_standard_python"] = "google"

g.tex_flavor = "latex"


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
opt.nrformats = "alpha"

opt.undofile = true
opt.undodir = vim.fn.stdpath('config') .. '/undo'
