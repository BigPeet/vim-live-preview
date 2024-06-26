if exists('g:vim_live_preview_loaded') || &cp || version < 700
  finish
endif
let g:vim_live_preview_loaded = 1

function! VLPTestFunction(start, end)
  let l:lines = getline(a:start, a:end)
  let l:lines = map(l:lines, 'substitute(v:val, "foo", "bar", "g")')
  return l:lines
endfunction

command! -range=% VLPTestFunctionCmd
      \ echo join(VLPTestFunction(<line1>, <line2>), "\n")

command! -nargs=1 -complete=function VLPFunc
      \ call vlp#EnterPreviewMode(function(<f-args>))
command! -nargs=1 -complete=command VLPCmd
      \ call vlp#EnterPreviewMode(<f-args>)
command! -nargs=1 VLP call vlp#EnterPreviewMode(<args>)
