if exists('g:clang_preprocessor_loaded') || &cp || version < 700
  finish
endif
let g:clang_preprocessor_loaded = 1

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

autocmd FileType c,cpp command! -range=% PreprocessLines
      \ echo join(s:Preprocess(<line1>, <line2>), "\n")

if &rtp =~ 'vim-live-preview'
  autocmd FileType c,cpp command! VLPPreprocessor
        \ call vlp#EnterPreviewMode(function("s:Preprocess"),
        \ {'preview_buffer_filetype': &ft,
        \ 'trigger_events': vlp#DefaultOptions()['trigger_events']})
  autocmd FileType c,cpp command! VLPPreprocessorCmd
        \ call vlp#EnterPreviewMode(":PreprocessLines",
        \ {'preview_buffer_filetype': &ft,
        \ 'trigger_events':
        \    vlp#DefaultOptions()['trigger_events'] + ['CursorHold']})
  autocmd FileType c,cpp command! VLPPreprocessorShell
        \ call vlp#EnterPreviewMode('!clang -E ' . shellescape(expand('%:p')),
        \ {'preview_buffer_filetype': &ft,
        \ 'trigger_events': ['BufWritePost']})
endif
