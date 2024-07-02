" AST example using clang

" This example demonstrates how VLP can be used to preview the AST of a C/C++
" file. The example uses clang to generate the AST.
"
" Four commands are created:
" - VLPAst: This command uses a function reference to generate the AST.
" - VLPAstCmd: This command names a Vim command to generate the AST.
" - VLPAstShell: This command uses a shell command to generate the AST.
"   Since this command uses the written file, we change the trigger event to
"   BufWritePost. This way, the AST is updated every time the file is saved.
" - VLPAstShellContent: This command uses a shell command to generate the AST
"   but reads the content of the buffer as input.
"
" All four methods do basically the same.
" This is just to show the different ways to achieve the same result.

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

autocmd FileType c,cpp command! -range=% CreateAST echo join(s:CreateAST(<line1>, <line2>), "\n")

if &rtp =~ 'vim-live-preview'
  let s:ast_options = {
        \ 'preview_buffer_filetype': &ft,
        \ 'preview_buffer_name': 'AST',
        \ }
  autocmd FileType c,cpp command! VLPAst call vlp#EnterPreviewMode(function("s:CreateAST"), s:ast_options)
  autocmd FileType c,cpp command! VLPAstCmd call vlp#EnterPreviewMode("CreateAST", s:ast_options)
  autocmd FileType c,cpp command! VLPAstShell call
        \ vlp#EnterPreviewMode('!clang -fsyntax-only -Xclang -ast-dump ',
        \   extend(copy(s:ast_options),
        \     {
        \       'input': 'fname',
        \       'trigger_events': ['BufWritePost'],
        \     }))
  autocmd FileType c,cpp command! VLPAstShellContent
        \ call vlp#EnterPreviewMode('!clang -fsyntax-only -x ' .
        \   ( &ft ==# 'c' ? 'c' : "c++" ) . ' -Xclang -ast-dump /dev/stdin',
        \   extend(copy(s:ast_options),
        \     {
        \       'input': 'content',
        \     }))
endif
