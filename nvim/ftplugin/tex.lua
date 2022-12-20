vim.g.vimtex_compiler_latexmk = {
  options = {
    '-pdf', '-pdflatex="xelatex --shell-escape %O %S"', '-verbose',
    '-file-line-error', '-synctex=1', '-interaction=nonstopmode'
  }
}
