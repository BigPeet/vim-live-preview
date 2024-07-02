" Query example using clang-query

" In this example, we use VLP to create a preview window for the output for
" clang-query. The query is run on the file that is currently being edited.
" The query itself is defined in the file passed to the command VLPQuery.
" Notably, the stderr is redirected to an additional window.
"
" Run this example by opening main.cpp and running the command:
"  :VLPQuery query-commands.txt
"
" Note: You can update the query-commands.txt while the preview mode is active
" but the preview window will only update when the C++ file is saved.


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
        \     'stderr': 'window',
        \   })
        \ | exec "10split " . <q-args> | wincmd p
endif
