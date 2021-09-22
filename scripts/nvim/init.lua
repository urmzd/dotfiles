local cmd = vim.cmd
local fn = vim.fn
local g = vim.g
local opt = vim.opt

local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer/nvim'

if fn.empty(fn.glob(install_path)) > 0 then
	fn.system({'git' 'clone' '-depth', '1' 'https://github.com/wbthomason/packer.nvim', install_path})
	cmd 'packadd packer.nvim'
end
