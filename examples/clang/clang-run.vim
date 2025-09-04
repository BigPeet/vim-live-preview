" Example using clang to compile and run the current C/C++ file.

" This example demonstrates how VLP can be used to compile the current C/C++
" file and then run it, displaying its output in a preview window.
" Optionally, you can pass arguments to the compiled program.

if executable('clang')
  let s:cc = 'clang'
elseif executable('gcc')
  let s:cc = 'gcc'
else
  echom 'Neither clang nor gcc is available.'
  finish
endif

if executable('clang++')
  let s:cxx = 'clang++'
elseif executable('g++')
  let s:cxx = 'g++'
else
  echom 'Neither clang++ nor g++ is available.'
  finish
endif

let s:output_file = '/tmp/vlp_cc.out'

function! s:CompileAndRunCurrentBuffer(run_args)
  let l:compiler = s:cxx
  if &filetype ==# 'c'
    let l:compiler = s:cc
  endif
  let l:cmd = l:compiler . ' -o ' . s:output_file . ' ' . shellescape(expand('%:p'))
  let l:timestamp = strftime('%Y-%m-%d %H:%M:%S')
  let l:out = system(l:cmd)
  let l:out = '=== Compiled at ' . l:timestamp . ' with ' . v:shell_error . ' ===' . "\n\n" . l:out
  if v:shell_error != 0
    return split(l:out, "\n")
  endif
  let l:run_cmd = s:output_file . ' ' . a:run_args
  let l:run_out = l:out . "=== Program output ===\n\n" . system(l:run_cmd)
  let l:run_out = l:run_out . "\n" . '=== Program exited with ' . v:shell_error . ' ==='
  return split(l:run_out, "\n")
endfunction

if &runtimepath =~# 'vim-live-preview'

  augroup VLPClangRun
    autocmd!
    autocmd FileType c,cpp command! -nargs=? VLPCompileAndRun
          \ call vlp#EnterPreviewMode(function("s:CompileAndRunCurrentBuffer", [<q-args>]),
          \ {
          \   'preview_buffer_filetype': "bash",
          \   'preview_buffer_name': 'Compile and Run Output',
          \   'input': 'none',
          \   'trigger_events': ['BufWritePost'],
          \ }
          \ )
  augroup END

endif
