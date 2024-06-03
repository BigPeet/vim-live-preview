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


function! s:PreprocessBuffer(bufnum)
  let l:tmpfile = tempname()
  call writefile(getbufline(a:bufnum, 1, "$"), l:tmpfile)
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


function! s:PreprocessFile()
  let l:lang = 'c++'
  if &ft ==# 'c'
    let l:lang = 'c'
  endif
  let l:cmd = "clang -E -x " . l:lang . " " . shellescape(expand('%:p'))
  let l:out = system(l:cmd)
  " filter out stuff not relevant to the file
  " e.g.
  let l:lines = split(l:out, "\n")
  call filter(l:lines, 'v:val !~? "^# [0-9]"')
  return l:lines
endfunction


autocmd FileType c,cpp command! -range=% Preprocess
      \ echo join(s:Preprocess(<line1>, <line2>), "\n")

autocmd FileType c,cpp command! -nargs=1 PreprocessBuffer
      \ echo join(s:PreprocessBuffer(<args>), "\n")

autocmd FileType c,cpp command! PreprocessFile
      \ echo join(s:PreprocessFile(), "\n")


" Check if the vim-live-preview plugin is installed
if &rtp =~ 'vim-live-preview'

  let s:common_options = {
        \ 'preview_buffer_filetype': &ft,
        \ 'preview_buffer_name': 'Preprocessed ' . expand('%:t'),
        \ }

  " Various examples how to hook into the preview system
  " Usage of the option dictionary is also showcased.
  autocmd FileType c,cpp command! VLPPreprocessor
        \ call vlp#EnterPreviewMode(function("s:Preprocess"),
        \ s:common_options
        \ )
  autocmd FileType c,cpp command! VLPPreprocessorBuffer
        \ call vlp#EnterPreviewMode(function("s:PreprocessBuffer"),
        \ extend(s:common_options,
        \ {
        \   'input': 'buffer',
        \ }))
  autocmd FileType c,cpp command! VLPPreprocessorFile
        \ call vlp#EnterPreviewMode(function("s:PreprocessFile"),
        \ extend(s:common_options,
        \ {
        \   'input': 'none',
        \   'trigger_events': ['BufWritePost'],
        \ }))
  autocmd FileType c,cpp command! VLPPreprocessorCmd
        \ call vlp#EnterPreviewMode(":Preprocess",
        \ extend(s:common_options,
        \ {
        \   'trigger_events':
        \     vlp#DefaultOptions()['trigger_events'] + ['CursorHold'],
        \ }))
  autocmd FileType c,cpp command! VLPPreprocessorBufferCmd
        \ call vlp#EnterPreviewMode(":PreprocessBuffer",
        \ extend(s:common_options,
        \ {
        \   'input': 'buffer',
        \ }))
  autocmd FileType c,cpp command! VLPPreprocessorFileCmd
        \ call vlp#EnterPreviewMode(":PreprocessFile",
        \ extend(s:common_options,
        \ {
        \   'input': 'none',
        \   'trigger_events': ['BufWritePost'],
        \ }))
  autocmd FileType c,cpp command! VLPPreprocessorShell
        \ call vlp#EnterPreviewMode('!clang -E -x ' .
        \   ( &ft ==# 'c' ? 'c' : "c++" ) . ' ',
        \ extend(s:common_options,
        \ {
        \   'input': 'fname',
        \   'trigger_events': ['BufWritePost'],
        \ }))
endif
