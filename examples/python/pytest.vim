if !executable("pytest")
  finish
endif

" Check if the vim-live-preview plugin is installed
if &rtp =~ 'vim-live-preview'
  autocmd FileType python command! -nargs=? VLPPytest call
        \ vlp#EnterPreviewMode(":!pytest " . <q-args>,
        \ {
        \   'input': 'none',
        \   'preview_buffer_name': 'pytest',
        \   'trigger_events': ['BufWritePost'],
        \ })
endif

