vim.g.tex_flavor = "latex"
vim.g.vimtex_compiler_latexmk = {
  options = {
    '-pdf', '-pdflatex="pdflatex --shell-escape %O %S"', '-verbose',
    '-file-line-error', '-synctex=1', '-interaction=nonstopmode'
  }
}
