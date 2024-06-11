if exists('g:clang_query_loaded') || &cp || version < 700
  finish
endif
let g:clang_query_loaded = 1

if !executable("clang-query")
  finish
endif

if &rtp =~ 'vim-live-preview'
  autocmd FileType c,cpp command! -nargs=1 -complete=file VLPQuery
        \ call vlp#EnterPreviewMode('!clang-query -f=' . <q-args> .
        \ ' <fname>',
        \   {
        \     'preview_buffer_filetype': &ft,
        \     'preview_buffer_name': 'Query',
        \     'input': 'fname',
        \     'trigger_events': ['BufWritePost'],
        \   })
        \ | exec "10split " . <q-args> | wincmd p
endif
