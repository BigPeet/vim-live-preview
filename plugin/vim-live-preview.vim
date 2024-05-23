if exists('g:vim_live_preview_loaded') || &cp || version < 700
  finish
endif
let g:vim_live_preview_loaded = 1

function! TestFunction(start, end)
  let l:lines = getline(a:start, a:end)
  let l:lines = map(l:lines, 'substitute(v:val, "foo", "bar", "g")')
  return l:lines
endfunction

command! -nargs=0 EnterPreviewMode call vlp#EnterPreviewMode('TestFunction')
