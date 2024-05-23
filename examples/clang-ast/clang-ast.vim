if exists('g:clang_ast_loaded') || &cp || version < 700
  finish
endif
let g:clang_ast_loaded = 1

if !executable("clang")
  finish
endif

function! s:CreateAST(start, end)
  let l:tmpfile = tempname()
  call writefile(getline(a:start, a:end), l:tmpfile)
  let l:lang = 'c++'
  if &ft ==# 'c'
    let l:lang = 'c'
  endif

  let l:cmd = "clang -fsyntax-only -fno-color-diagnostics -Xclang -ast-dump -x"
        \ . " " . l:lang . " " . shellescape(l:tmpfile)
  let l:out = system(l:cmd)
  " filter out translation unit declaration or stuff not relevant to the file
  " at hand
  " ...
  return split(l:out, "\n")
endfunction

if &rtp =~ 'vim-live-preview'
  autocmd FileType c,cpp command! VLPAst call vlp#EnterPreviewMode(function("s:CreateAST"))
endif
