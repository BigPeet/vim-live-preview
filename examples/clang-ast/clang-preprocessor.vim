if exists('g:clang_ast_loaded') || &cp || version < 700
  finish
endif
let g:clang_ast_loaded = 1

if !executable("clang")
  finish
endif

function! s:Preprocess(start, end)
  let l:tmpfile = tempname()
  call writefile(getline(a:start, a:end), l:tmpfile)
  let l:lang = 'c++'
  if &ft ==# 'c'
    let l:lang = 'c'
  endif

  let l:cmd = "clang -E -x " . l:lang . " " . shellescape(l:tmpfile)
  let l:out = system(l:cmd)
  " filter out stuff not relevant to the file
  " e.g.
  let l:lines = split(l:out, "\n")
  call filter(l:lines, 'v:val !~? "^# [0-9]"')
  return l:lines
endfunction

if &rtp =~ 'vim-live-preview'
  autocmd FileType c,cpp command! VLPPreprocessor call vlp#EnterPreviewMode(function("s:Preprocess"))
endif
